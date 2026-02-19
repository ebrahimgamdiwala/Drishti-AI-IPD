/// Voice-Controlled Camera Screen
///
/// Opens a full-screen camera preview where all controls are voice-activated.
/// Commands:
///   "take photo" / "click" / "capture" / "snap" / "shoot" → capture image
///   "switch camera" / "flip" / "front camera" / "back camera" → switch lens
///   "skip" / "cancel" → exit without taking a photo
library;

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/voice_service.dart';

class VoiceCameraScreen extends StatefulWidget {
  /// Instruction spoken when camera is ready (should be in current TTS language)
  final String instruction;

  const VoiceCameraScreen({super.key, required this.instruction});

  @override
  State<VoiceCameraScreen> createState() => _VoiceCameraScreenState();
}

class _VoiceCameraScreenState extends State<VoiceCameraScreen>
    with WidgetsBindingObserver {
  final _voiceService = VoiceService();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _isCapturing = false;
  bool _done = false;
  String _statusText = 'Initializing camera...';
  bool _isListening = false;
  bool _cameraReady = false;

  /// Human-readable label for the active lens direction ("Back" / "Front")
  String _cameraLabel = 'Back';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('[VoiceCameraScreen] No cameras available');
        if (mounted) Navigator.pop(context, null);
        return;
      }

      // Prefer back camera as default
      final backIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = backIdx >= 0 ? backIdx : 0;

      await _activateCamera(_cameraIndex);

      final label = _dirLabel(_cameras[_cameraIndex].lensDirection);
      if (!mounted) return;
      setState(() {
        _cameraReady = true;
        _cameraLabel = label;
        _statusText =
            '$label camera. Say "take photo", "switch camera", or "skip"';
      });

      // Announce camera direction + instructions
      await _voiceService.speak('$label camera ready. ${widget.instruction}');
      _startVoiceLoop();
    } catch (e) {
      debugPrint('[VoiceCameraScreen] Camera init error: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  Future<void> _activateCamera(int index) async {
    // Step 1: grab old controller and immediately null it out so the
    //         preview widget stops rendering — this frees the hardware lock.
    final old = _controller;
    if (mounted) setState(() => _controller = null);

    // Step 2: dispose old controller BEFORE opening the new camera.
    //         On Android only one camera can be open at a time, so we must
    //         fully release the current lens before acquiring the next one.
    try {
      await old?.dispose();
    } catch (e) {
      debugPrint('[VoiceCameraScreen] Old controller dispose error: $e');
    }

    // Step 3: brief settle time for the camera hardware to fully release.
    await Future.delayed(const Duration(milliseconds: 120));

    // Step 4: create and initialize the new controller.
    final newController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await newController.initialize();
    } catch (e) {
      debugPrint('[VoiceCameraScreen] New controller init error: $e');
      await newController.dispose();
      return;
    }

    if (!mounted) {
      await newController.dispose();
      return;
    }

    // Step 5: show the new preview.
    setState(() {
      _cameraIndex = index;
      _controller = newController;
      _cameraLabel = _dirLabel(_cameras[index].lensDirection);
    });
  }

  /// Returns a human-readable label for a [CameraLensDirection].
  String _dirLabel(CameraLensDirection dir) =>
      dir == CameraLensDirection.front ? 'Front' : 'Back';

  Future<void> _startVoiceLoop() async {
    while (mounted && !_done) {
      if (_isCapturing) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      if (mounted) setState(() => _isListening = true);

      // Small buffer after any TTS
      await Future.delayed(const Duration(milliseconds: 400));

      if (_done || !mounted) break;

      final completer = _ResultCompleter();
      await _voiceService.startListening(
        onResult: (text) => completer.complete(text),
        onError: (_) => completer.complete(null),
        listenFor: const Duration(seconds: 12),
      );

      if (mounted) setState(() => _isListening = false);

      final result = completer.value;
      if (result != null && result.isNotEmpty) {
        await _handleCommand(result);
      }
    }
  }

  Future<void> _handleCommand(String rawText) async {
    if (_done) return;
    final text = rawText.toLowerCase().trim();
    debugPrint('[VoiceCameraScreen] Command: "$text"');

    final isCapture =
        text.contains('take') ||
        text.contains('capture') ||
        text.contains('click') ||
        text.contains('snap') ||
        text.contains('shoot') ||
        text.contains('photo') ||
        text.contains('picture') ||
        text.contains('pic');

    final isSkip =
        text.contains('skip') ||
        text.contains('cancel') ||
        text.contains('no photo') ||
        text.contains('never mind');

    final isFront = text.contains('front') || text.contains('selfie');
    final isBack = text.contains('back') || text.contains('rear');
    final isSwitch =
        text.contains('switch') || text.contains('flip') || isFront || isBack;

    if (isCapture) {
      await _capturePhoto();
    } else if (isSwitch) {
      if (isFront) {
        await _switchToDirection(CameraLensDirection.front);
      } else if (isBack) {
        await _switchToDirection(CameraLensDirection.back);
      } else {
        await _toggleCamera();
      }
    } else if (isSkip) {
      _done = true;
      if (mounted) Navigator.pop(context, null);
    } else {
      // Unrecognised — re-prompt briefly
      if (mounted) {
        setState(
          () => _statusText = 'Say "take photo", "switch camera", or "skip"',
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }
    setState(() {
      _isCapturing = true;
      _statusText = 'Capturing...';
    });
    _done = true;

    try {
      final xFile = await _controller!.takePicture();
      await _voiceService.speak('Photo captured.');
      if (mounted) Navigator.pop(context, File(xFile.path));
    } catch (e) {
      debugPrint('[VoiceCameraScreen] Capture error: $e');
      setState(() {
        _isCapturing = false;
        _done = false;
        _statusText = 'Error capturing. Try again.';
      });
      await _voiceService.speak('Could not capture photo. Please try again.');
    }
  }

  Future<void> _switchToDirection(CameraLensDirection dir) async {
    final idx = _cameras.indexWhere((c) => c.lensDirection == dir);
    if (idx < 0) {
      await _voiceService.speak('${dir.name} camera not available.');
      return;
    }
    final dirName = _dirLabel(dir);
    setState(() => _statusText = 'Switching to $dirName camera...');
    await _activateCamera(idx);
    await _voiceService.speak('Switched to $dirName camera.');
    if (mounted) {
      setState(
        () => _statusText =
            '$dirName camera. Say "take photo", "switch camera", or "skip"',
      );
    }
  }

  Future<void> _toggleCamera() async {
    final newIdx = (_cameraIndex + 1) % _cameras.length;
    final dirName = _dirLabel(_cameras[newIdx].lensDirection);
    setState(() => _statusText = 'Switching to $dirName camera...');
    await _activateCamera(newIdx);
    await _voiceService.speak('Switched to $dirName camera.');
    if (mounted) {
      setState(
        () => _statusText =
            '$dirName camera. Say "take photo", "switch camera", or "skip"',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _activateCamera(_cameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _done = true;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_cameraReady &&
              _controller != null &&
              _controller!.value.isInitialized)
            _buildCameraPreview()
          else
            _buildLoadingView(),

          // Top bar
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // Bottom status bar
          Positioned(bottom: 0, left: 0, right: 0, child: _buildStatusBar()),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Use FittedBox+SizedBox with swapped preview dimensions so the camera
    // fills the full screen without OverflowBox rendering artifacts.
    final previewSize = _controller!.value.previewSize;
    final pw =
        previewSize?.height ?? 480.0; // camera preview is landscape-native
    final ph = previewSize?.width ?? 640.0; // swap for portrait display
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: pw,
          height: ph,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () {
              _done = true;
              Navigator.pop(context, null);
            },
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Voice Camera',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_cameraLabel camera',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          // Switch camera button
          IconButton(
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _isCapturing ? null : _toggleCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 24,
          left: 16,
          right: 16,
          top: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mic / listening indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _isListening ? 'Listening...' : _statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tap-to-capture button (fallback)
            GestureDetector(
              onTap: _isCapturing ? null : _capturePhoto,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _isCapturing
                      ? Colors.grey.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                ),
                child: _isCapturing
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.camera, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Or tap to capture',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple completer wrapper for the voice loop
class _ResultCompleter {
  String? _value;
  bool _completed = false;

  String? get value => _value;

  void complete(String? val) {
    if (!_completed) {
      _completed = true;
      _value = val;
    }
  }
}
