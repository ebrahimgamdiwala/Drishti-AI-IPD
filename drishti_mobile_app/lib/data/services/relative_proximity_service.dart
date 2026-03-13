/// Offline-capable relative proximity monitoring using camera stream.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import '../models/activity_model.dart';
import '../models/relative_model.dart';
import 'activity_log_service.dart';
import 'local_face_embedding_service.dart';
import 'voice_service.dart';

class RelativeProximityService {
  static final RelativeProximityService _instance =
      RelativeProximityService._internal();

  factory RelativeProximityService() => _instance;

  RelativeProximityService._internal();

  final LocalFaceEmbeddingService _embeddingService =
      LocalFaceEmbeddingService();
  final VoiceService _voiceService = VoiceService();
  final ActivityLogService _activityLogService = ActivityLogService();

  CameraController? _controller;
  bool _isMonitoring = false;
  bool _isProcessing = false;
  bool _isSwitchingCamera = false;
  DateTime? _lastSwitchAt;
  DateTime? _lastAnnouncement;
  String? _lastName;
  DateTime? _lastFrameProcessedAt;
  List<RelativeModel> _activeRelatives = const [];

  // Fixed stabilization delay before camera switching to avoid black preview races.
  static const Duration _switchStabilizationDelay = Duration(milliseconds: 700);
  static const Duration _switchCooldown = Duration(milliseconds: 2200);
  static const Duration _frameProcessInterval = Duration(milliseconds: 1800);

  bool get isMonitoring => _isMonitoring;
  CameraController? get previewController => _controller;

  Future<void> _startFrameStream(CameraController controller) async {
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }

    await controller.startImageStream((CameraImage frame) {
      if (!_isMonitoring || _isSwitchingCamera || _isProcessing) {
        return;
      }

      final now = DateTime.now();
      if (_lastFrameProcessedAt != null &&
          now.difference(_lastFrameProcessedAt!) < _frameProcessInterval) {
        return;
      }
      _lastFrameProcessedAt = now;

      unawaited(_processFrame(frame));
    });
  }

  Future<void> _stopFrameStream(CameraController? controller) async {
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (!controller.value.isStreamingImages) return;

    try {
      await controller.stopImageStream();
    } catch (_) {
      // Some devices throw if stream already stopping; safe to ignore.
    }
  }

  CameraController _buildController(CameraDescription description) {
    return CameraController(
      description,
      ResolutionPreset.low,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
  }

  Future<void> startMonitoring(List<RelativeModel> relatives) async {
    if (_isMonitoring) return;

    final candidates = relatives
        .where((r) => r.localFaceEmbeddings.isNotEmpty)
        .toList(growable: false);
    if (candidates.isEmpty) {
      throw Exception('No local relative embeddings available for monitoring.');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera available for relative monitoring.');
    }

    final backIndex = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    final selected = cameras[backIndex >= 0 ? backIndex : 0];

    _controller = _buildController(selected);

    await _controller!.initialize();
    _isMonitoring = true;
    _isProcessing = false;
    _isSwitchingCamera = false;
    _lastSwitchAt = null;
    _lastAnnouncement = null;
    _lastName = null;
    _lastFrameProcessedAt = null;
    _activeRelatives = candidates;

    await _startFrameStream(_controller!);
  }

  Future<bool> switchCamera() async {
    if (!_isMonitoring || _isSwitchingCamera) {
      return false;
    }

    final lastSwitch = _lastSwitchAt;
    if (lastSwitch != null &&
        DateTime.now().difference(lastSwitch) < _switchCooldown) {
      return false;
    }

    final current = _controller;
    if (current == null) {
      return false;
    }

    _isSwitchingCamera = true;
    try {
      // Use a fixed interval before switching, as requested, so camera pipeline settles.
      await Future.delayed(_switchStabilizationDelay);

      // Avoid swapping controllers while a capture is in flight.
      int waitMs = 0;
      while (_isProcessing && waitMs < 1200) {
        await Future.delayed(const Duration(milliseconds: 60));
        waitMs += 60;
      }

      await _stopFrameStream(current);
      _controller = null;

      // Keep only one active camera session during switch. On some OEM stacks,
      // opening the next camera before disposing the current one causes preview
      // teardown and surface leaks.
      try {
        await current.dispose();
      } catch (_) {
        // Continue with best effort; some devices throw on racey teardown.
      }

      // Small gap helps camera service settle before next open on some devices.
      await Future.delayed(const Duration(milliseconds: 220));

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return false;
      }

      final currentLens = current.description.lensDirection;
      final targetLens = currentLens == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      int targetIndex = cameras.indexWhere(
        (c) => c.lensDirection == targetLens,
      );
      if (targetIndex < 0) {
        targetIndex = 0;
      }

      final nextController = _buildController(cameras[targetIndex]);

      await nextController.initialize();
      _controller = nextController;
      _lastFrameProcessedAt = null;

      await _startFrameStream(nextController);

      _lastSwitchAt = DateTime.now();

      return true;
    } catch (_) {
      if (_isMonitoring) {
        final controller = _controller;
        if (controller != null) {
          await _startFrameStream(controller);
        }
      }
      return false;
    } finally {
      _isSwitchingCamera = false;
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    final controller = _controller;
    _controller = null;
    _activeRelatives = const [];
    _lastFrameProcessedAt = null;
    if (controller != null) {
      await _stopFrameStream(controller);
      await controller.dispose();
    }
  }

  Future<void> _processFrame(CameraImage frame) async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isProcessing ||
        _isSwitchingCamera) {
      return;
    }

    _isProcessing = true;
    try {
      final jpegBytes = _cameraImageToJpegBytes(frame);
      if (jpegBytes == null || jpegBytes.isEmpty) {
        return;
      }

      final frameEmbedding = await _embeddingService.embeddingFromBytes(
        jpegBytes,
      );
      if (frameEmbedding == null || frameEmbedding.isEmpty) {
        return;
      }

      RelativeModel? bestRelative;
      double bestScore = -1;
      for (final relative in _activeRelatives) {
        for (final emb in relative.localFaceEmbeddings) {
          final score = _embeddingService.cosineSimilarity(frameEmbedding, emb);
          if (score > bestScore) {
            bestScore = score;
            bestRelative = relative;
          }
        }
      }

      if (bestRelative == null) return;
      if (bestScore < 0.58) return;

      final now = DateTime.now();
      if (_lastAnnouncement != null) {
        final delta = now.difference(_lastAnnouncement!);
        if (_lastName == bestRelative.name && delta.inSeconds < 8) {
          return;
        }
      }

      final distanceWord = bestScore >= 0.68 ? 'close' : 'approaching';
      _lastAnnouncement = now;
      _lastName = bestRelative.name;
      unawaited(_voiceService.speak('${bestRelative.name} $distanceWord'));

      await _activityLogService.addLog(
        type: ActivityType.identify,
        title: 'Relative detected',
        description:
            '${bestRelative.name} (${bestRelative.relationship}) is $distanceWord',
        severity: bestScore >= 0.68 ? 'high' : 'medium',
        isImportant: true,
        metadata: {'relative_id': bestRelative.id, 'score': bestScore},
      );
    } catch (_) {
      // Keep monitoring loop resilient to camera/model hiccups.
    } finally {
      _isProcessing = false;
    }
  }

  Uint8List? _cameraImageToJpegBytes(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.bgra8888) {
        final converted = _fromBgra8888(image);
        if (converted == null) return null;
        return Uint8List.fromList(img.encodeJpg(converted, quality: 82));
      }

      if (image.format.group != ImageFormatGroup.yuv420 ||
          image.planes.length < 3) {
        return null;
      }

      final converted = _fromYuv420(image);
      if (converted == null) return null;
      return Uint8List.fromList(img.encodeJpg(converted, quality: 82));
    } catch (_) {
      return null;
    }
  }

  img.Image? _fromBgra8888(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    final imageOut = img.Image(width: width, height: height);

    int offset = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final b = bytes[offset];
        final g = bytes[offset + 1];
        final r = bytes[offset + 2];
        imageOut.setPixelRgb(x, y, r, g, b);
        offset += 4;
      }
    }

    return imageOut;
  }

  img.Image? _fromYuv420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    final imageOut = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvY = y >> 1;
        final uvX = x >> 1;
        final uIndex = uvY * uRowStride + uvX * uPixelStride;
        final vIndex = uvY * vRowStride + uvX * vPixelStride;

        final yp = yBytes[yIndex].toDouble();
        final up = uBytes[uIndex].toDouble() - 128.0;
        final vp = vBytes[vIndex].toDouble() - 128.0;

        int r = (yp + 1.402 * vp).round();
        int g = (yp - 0.344136 * up - 0.714136 * vp).round();
        int b = (yp + 1.772 * up).round();

        if (r < 0) r = 0;
        if (r > 255) r = 255;
        if (g < 0) g = 0;
        if (g > 255) g = 255;
        if (b < 0) b = 0;
        if (b > 255) b = 255;

        imageOut.setPixelRgb(x, y, r, g, b);
      }
    }

    return imageOut;
  }
}
