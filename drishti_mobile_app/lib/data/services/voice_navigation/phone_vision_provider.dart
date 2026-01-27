import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../models/voice_navigation/vision_result.dart';
import '../../models/voice_navigation/safety_result.dart';
import '../../models/voice_navigation/detected_object.dart';
import '../../models/voice_navigation/bounding_box.dart';
import '../../models/voice_navigation/clock_position.dart';
import '../../models/voice_navigation/hazard.dart';
import '../../models/voice_navigation/hazard_level.dart';
import '../local_vlm_service.dart';
import '../api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'vision_provider.dart';

/// Phone Vision Provider - Implementation using device camera
///
/// This implementation uses the device camera to capture frames and
/// analyzes them using either backend VLM or local VLM (fallback).
///
/// Requirements: 4.2, 4.3, 4.4, 4.5
class PhoneVisionProvider implements VisionProvider {
  final ImagePicker _imagePicker;
  final LocalVLMService _localVLM;
  final ApiService _apiService;

  /// Whether to use local model (true) or backend (false)
  bool _useLocalModel = false;

  /// Cached frame for follow-up questions
  Uint8List? _cachedFrame;
  File? _cachedFrameFile;

  /// List of dangerous object labels for safety detection
  static const List<String> _dangerousObjects = [
    'car',
    'vehicle',
    'truck',
    'bus',
    'motorcycle',
    'bike',
    'stairs',
    'staircase',
    'step',
    'steps',
    'hole',
    'pit',
    'gap',
    'ditch',
    'fire',
    'flame',
    'smoke',
    'water',
    'pool',
    'pond',
    'lake',
    'river',
    'cliff',
    'edge',
    'drop',
    'ledge',
    'construction',
    'barrier',
    'caution',
  ];

  PhoneVisionProvider({
    ImagePicker? imagePicker,
    required LocalVLMService localVLM,
    required ApiService apiService,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _localVLM = localVLM,
       _apiService = apiService;

  @override
  Future<VisionResult> analyzeCurrentView({String? customPrompt}) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Capture frame from camera
      final frame = await _captureFrame();
      if (frame == null) {
        throw Exception('Failed to capture camera frame');
      }

      // Cache the frame for follow-up questions
      _cachedFrame = frame;

      // Determine prompt
      final prompt =
          customPrompt ??
          'Describe what you see in this image. Focus on objects, people, and any potential obstacles or hazards.';

      // Try backend first, fall back to local
      VisionResult result;
      if (!_useLocalModel) {
        try {
          result = await _analyzeWithBackend(frame, prompt);
        } catch (e) {
          debugPrint(
            '[PhoneVisionProvider] Backend failed: $e, falling back to local',
          );
          _useLocalModel = true;
          result = await _analyzeWithLocal(frame, prompt);
        }
      } else {
        result = await _analyzeWithLocal(frame, prompt);
      }

      stopwatch.stop();

      return VisionResult(
        description: result.description,
        objects: result.objects,
        processingTime: stopwatch.elapsed,
        usedLocalModel: _useLocalModel,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[PhoneVisionProvider] Error in analyzeCurrentView: $e');
      rethrow;
    }
  }

  @override
  Future<VisionResult> detectObstacles() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Capture frame
      final frame = await _captureFrame();
      if (frame == null) {
        throw Exception('Failed to capture camera frame');
      }

      _cachedFrame = frame;

      // Specialized prompt for obstacle detection
      const prompt =
          'Identify any obstacles or objects that could block movement or navigation. '
          'List each obstacle with its approximate location.';

      // Try backend first, fall back to local
      VisionResult result;
      if (!_useLocalModel) {
        try {
          result = await _analyzeWithBackend(frame, prompt);
        } catch (e) {
          debugPrint(
            '[PhoneVisionProvider] Backend failed: $e, falling back to local',
          );
          _useLocalModel = true;
          result = await _analyzeWithLocal(frame, prompt);
        }
      } else {
        result = await _analyzeWithLocal(frame, prompt);
      }

      stopwatch.stop();

      return VisionResult(
        description: result.description,
        objects: result.objects,
        processingTime: stopwatch.elapsed,
        usedLocalModel: _useLocalModel,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[PhoneVisionProvider] Error in detectObstacles: $e');
      rethrow;
    }
  }

  @override
  Future<VisionResult> identifyPeople() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Capture frame
      final frame = await _captureFrame();
      if (frame == null) {
        throw Exception('Failed to capture camera frame');
      }

      _cachedFrame = frame;

      // Specialized prompt for people identification
      const prompt =
          'Identify all people in this image. '
          'Describe their approximate location and any distinguishing features.';

      // Try backend first, fall back to local
      VisionResult result;
      if (!_useLocalModel) {
        try {
          result = await _analyzeWithBackend(frame, prompt);
        } catch (e) {
          debugPrint(
            '[PhoneVisionProvider] Backend failed: $e, falling back to local',
          );
          _useLocalModel = true;
          result = await _analyzeWithLocal(frame, prompt);
        }
      } else {
        result = await _analyzeWithLocal(frame, prompt);
      }

      stopwatch.stop();

      return VisionResult(
        description: result.description,
        objects: result.objects,
        processingTime: stopwatch.elapsed,
        usedLocalModel: _useLocalModel,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[PhoneVisionProvider] Error in identifyPeople: $e');
      rethrow;
    }
  }

  @override
  Future<VisionResult> readText() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Capture frame
      final frame = await _captureFrame();
      if (frame == null) {
        throw Exception('Failed to capture camera frame');
      }

      _cachedFrame = frame;

      // Specialized prompt for text reading
      const prompt =
          'Read and transcribe all visible text in this image. '
          'Include signs, labels, documents, or any written content.';

      // Try backend first, fall back to local
      VisionResult result;
      if (!_useLocalModel) {
        try {
          result = await _analyzeWithBackend(frame, prompt);
        } catch (e) {
          debugPrint(
            '[PhoneVisionProvider] Backend failed: $e, falling back to local',
          );
          _useLocalModel = true;
          result = await _analyzeWithLocal(frame, prompt);
        }
      } else {
        result = await _analyzeWithLocal(frame, prompt);
      }

      stopwatch.stop();

      return VisionResult(
        description: result.description,
        objects: result.objects,
        processingTime: stopwatch.elapsed,
        usedLocalModel: _useLocalModel,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[PhoneVisionProvider] Error in readText: $e');
      rethrow;
    }
  }

  @override
  Future<SafetyResult> checkForHazards() async {
    try {
      // Capture frame
      final frame = await _captureFrame();
      if (frame == null) {
        throw Exception('Failed to capture camera frame');
      }

      _cachedFrame = frame;

      // Specialized prompt for hazard detection
      const prompt =
          'Identify any dangerous objects or hazards in this image. '
          'Focus on vehicles, stairs, holes, fire, water, cliffs, or any immediate dangers. '
          'For each hazard, estimate its distance and location.';

      // Try backend first, fall back to local
      VisionResult visionResult;
      if (!_useLocalModel) {
        try {
          visionResult = await _analyzeWithBackend(frame, prompt);
        } catch (e) {
          debugPrint(
            '[PhoneVisionProvider] Backend failed: $e, falling back to local',
          );
          _useLocalModel = true;
          visionResult = await _analyzeWithLocal(frame, prompt);
        }
      } else {
        visionResult = await _analyzeWithLocal(frame, prompt);
      }

      // Extract hazards from detected objects
      final hazards = <Hazard>[];
      for (final obj in visionResult.objects) {
        if (_isDangerous(obj.label)) {
          final distance = _estimateDistance(obj.boundingBox);
          final level = _classifyHazardLevel(obj, distance);

          hazards.add(
            Hazard(
              type: obj.label,
              level: level,
              position: obj.clockPosition,
              distance: distance,
            ),
          );
        }
      }

      // Generate warning message if hazards found
      if (hazards.isEmpty) {
        return const SafetyResult.safe();
      }

      final warningMessage = _generateWarning(hazards);

      return SafetyResult(
        hasDanger: true,
        hazards: hazards,
        warningMessage: warningMessage,
      );
    } catch (e) {
      debugPrint('[PhoneVisionProvider] Error in checkForHazards: $e');
      rethrow;
    }
  }

  @override
  Future<Uint8List?> getCurrentFrame() async {
    // Return cached frame if available, otherwise capture new one
    if (_cachedFrame != null) {
      return _cachedFrame;
    }

    return await _captureFrame();
  }

  /// Capture a single frame from the camera
  Future<Uint8List?> _captureFrame() async {
    try {
      // Use image picker to capture from camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[PhoneVisionProvider] User cancelled camera capture');
        return null;
      }

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Cache the file for local VLM (more efficient)
      _cachedFrameFile = File(image.path);

      return bytes;
    } catch (e) {
      debugPrint('[PhoneVisionProvider] Error capturing frame: $e');
      rethrow;
    }
  }

  /// Analyze frame with backend VLM
  Future<VisionResult> _analyzeWithBackend(
    Uint8List frame,
    String prompt,
  ) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(frame, filename: 'frame.jpg'),
        'prompt': prompt,
      });

      // Send to backend
      final response = await _apiService.postFormData(
        ApiEndpoints.analyze,
        formData,
      );

      if (response.statusCode != 200) {
        throw Exception('Backend returned status ${response.statusCode}');
      }

      // Parse response
      final data = response.data as Map<String, dynamic>;
      final description = data['description'] as String? ?? '';
      final objectsData = data['objects'] as List<dynamic>? ?? [];

      // Parse detected objects
      final objects = objectsData.map((obj) {
        final objMap = obj as Map<String, dynamic>;
        final bbox = objMap['bounding_box'] as Map<String, dynamic>;
        final boundingBox = BoundingBox(
          x: (bbox['x'] as num).toDouble(),
          y: (bbox['y'] as num).toDouble(),
          width: (bbox['width'] as num).toDouble(),
          height: (bbox['height'] as num).toDouble(),
        );

        return DetectedObject(
          label: objMap['label'] as String,
          confidence: (objMap['confidence'] as num).toDouble(),
          boundingBox: boundingBox,
          clockPosition: _toClockPosition(boundingBox),
        );
      }).toList();

      return VisionResult(
        description: description,
        objects: objects,
        processingTime: Duration.zero, // Will be set by caller
        usedLocalModel: false,
      );
    } catch (e) {
      debugPrint('[PhoneVisionProvider] Backend analysis error: $e');
      rethrow;
    }
  }

  /// Analyze frame with local VLM
  Future<VisionResult> _analyzeWithLocal(Uint8List frame, String prompt) async {
    try {
      // Check if local VLM is ready
      if (!_localVLM.isReady) {
        throw Exception('Local VLM not initialized');
      }

      // Use cached file if available (more efficient for local VLM)
      VLMResponse response;
      if (_cachedFrameFile != null && await _cachedFrameFile!.exists()) {
        response = await _localVLM.analyzeImageFromFile(
          imageFile: _cachedFrameFile!,
          prompt: prompt,
        );
      } else {
        response = await _localVLM.analyzeImage(
          imageBytes: frame,
          prompt: prompt,
        );
      }

      // Parse response text to extract objects
      // Note: Local VLM returns text description, not structured objects
      // We'll create a simple object list based on keywords
      final objects = _extractObjectsFromDescription(response.text);

      return VisionResult(
        description: response.text,
        objects: objects,
        processingTime: Duration.zero, // Will be set by caller
        usedLocalModel: true,
      );
    } catch (e) {
      debugPrint('[PhoneVisionProvider] Local VLM analysis error: $e');
      rethrow;
    }
  }

  /// Extract objects from text description (simple keyword matching)
  List<DetectedObject> _extractObjectsFromDescription(String description) {
    final objects = <DetectedObject>[];
    final lowerDesc = description.toLowerCase();

    // Simple keyword matching for common objects
    final keywords = [
      'person',
      'people',
      'man',
      'woman',
      'child',
      'car',
      'vehicle',
      'truck',
      'bus',
      'motorcycle',
      'stairs',
      'steps',
      'door',
      'window',
      'wall',
      'table',
      'chair',
      'desk',
      'bed',
      'tree',
      'plant',
      'flower',
      'sign',
      'text',
      'label',
    ];

    for (final keyword in keywords) {
      if (lowerDesc.contains(keyword)) {
        // Create a generic bounding box (center of image)
        final bbox = const BoundingBox(x: 0.4, y: 0.4, width: 0.2, height: 0.2);

        objects.add(
          DetectedObject(
            label: keyword,
            confidence: 0.7, // Generic confidence for text-based detection
            boundingBox: bbox,
            clockPosition: _toClockPosition(bbox),
          ),
        );
      }
    }

    return objects;
  }

  /// Convert bounding box to clock position
  ClockPosition _toClockPosition(BoundingBox box) {
    // Calculate center of bounding box
    final centerX = box.centerX;
    final centerY = box.centerY;

    // Map to clock position (12 = top, 3 = right, 6 = bottom, 9 = left)
    // Using atan2 to get angle, then convert to clock hour

    // Normalize to center of image (0.5, 0.5)
    final dx = centerX - 0.5;
    final dy = centerY - 0.5;

    // Calculate angle in radians (-π to π)
    // Note: Y increases downward in image coordinates
    final angle = math.atan2(-dy, dx); // Negate dy to flip Y axis

    // Convert to degrees (0-360)
    var degrees = angle * 180 / math.pi;
    if (degrees < 0) degrees += 360;

    // Convert to clock hour (12 = 0°, 3 = 90°, 6 = 180°, 9 = 270°)
    // Rotate by 90° so 12 o'clock is at top
    degrees = (degrees + 90) % 360;

    // Map to clock hour (1-12)
    final hour = ((degrees / 30).round() % 12);
    final clockHour = hour == 0 ? 12 : hour;

    // Generate description
    String description;
    if (clockHour == 12) {
      description = 'directly ahead';
    } else if (clockHour == 6) {
      description = 'directly behind';
    } else if (clockHour == 3) {
      description = 'to your right';
    } else if (clockHour == 9) {
      description = 'to your left';
    } else {
      description = 'at $clockHour o\'clock';
    }

    return ClockPosition(clockHour, description);
  }

  /// Check if object label is dangerous
  bool _isDangerous(String label) {
    final lowerLabel = label.toLowerCase();
    return _dangerousObjects.any(
      (dangerous) => lowerLabel.contains(dangerous.toLowerCase()),
    );
  }

  /// Estimate distance from bounding box size
  /// Larger objects are assumed to be closer
  double _estimateDistance(BoundingBox box) {
    // Simple heuristic: distance inversely proportional to area
    // Larger area = closer object
    final area = box.area;

    if (area > 0.3) {
      return 1.0; // Very close (< 2m)
    } else if (area > 0.15) {
      return 2.5; // Close (2-3m)
    } else if (area > 0.05) {
      return 5.0; // Medium (3-7m)
    } else {
      return 10.0; // Far (> 7m)
    }
  }

  /// Classify hazard level based on object and distance
  HazardLevel _classifyHazardLevel(DetectedObject object, double distance) {
    final label = object.label.toLowerCase();

    // Critical hazards (immediate danger)
    if (distance < 2.0) {
      if (label.contains('vehicle') ||
          label.contains('car') ||
          label.contains('truck') ||
          label.contains('fire') ||
          label.contains('cliff')) {
        return HazardLevel.critical;
      }
    }

    // High hazards (serious concern)
    if (distance < 3.0) {
      if (label.contains('stairs') ||
          label.contains('hole') ||
          label.contains('water') ||
          label.contains('edge')) {
        return HazardLevel.high;
      }
    }

    // Medium hazards (caution required)
    if (distance < 5.0) {
      if (_isDangerous(label)) {
        return HazardLevel.medium;
      }
    }

    // Low hazards (awareness needed)
    return HazardLevel.low;
  }

  /// Generate warning message from hazards
  String _generateWarning(List<Hazard> hazards) {
    if (hazards.isEmpty) return '';

    // Sort by severity (critical first)
    hazards.sort((a, b) => b.level.index.compareTo(a.level.index));

    // Get most critical hazard
    final critical = hazards.first;

    // Generate warning based on severity
    if (critical.level == HazardLevel.critical) {
      return 'Stop. ${critical.type} ${critical.position.description}.';
    } else if (critical.level == HazardLevel.high) {
      return 'Caution. ${critical.type} ${critical.position.description}.';
    } else if (critical.level == HazardLevel.medium) {
      return '${critical.type} detected ${critical.position.description}.';
    } else {
      return '${critical.type} nearby ${critical.position.description}.';
    }
  }

  /// Clear cached frame
  void clearCache() {
    _cachedFrame = null;
    _cachedFrameFile = null;
  }

  /// Reset to try backend again
  void resetBackendPreference() {
    _useLocalModel = false;
  }
}
