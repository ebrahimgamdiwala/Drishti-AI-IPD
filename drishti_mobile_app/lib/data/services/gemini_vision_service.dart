/// Backend-proxied cloud vision analysis with structured output.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../models/voice_navigation/bounding_box.dart';
import '../models/voice_navigation/clock_position.dart';
import '../models/voice_navigation/detected_object.dart';
import 'api_service.dart';

class GeminiVisionResult {
  final String description;
  final List<DetectedObject> objects;
  final int promptTokens;
  final int completionTokens;
  final Duration inferenceTime;
  final String model;

  const GeminiVisionResult({
    required this.description,
    required this.objects,
    required this.promptTokens,
    required this.completionTokens,
    required this.inferenceTime,
    required this.model,
  });
}

class GeminiVisionService {
  static final GeminiVisionService _instance = GeminiVisionService._internal();

  factory GeminiVisionService() => _instance;

  GeminiVisionService._internal();

  final ApiService _apiService = ApiService();

  bool get isConfigured => ApiEndpoints.baseUrl.trim().isNotEmpty;

  static bool isConnectivityOrServiceFailure(Object error) {
    if (error is SocketException) {
      return true;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.cancel:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          return statusCode == 408 || statusCode == 429 || statusCode >= 500;
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return error.error is SocketException;
      }
    }

    return false;
  }

  Future<GeminiVisionResult> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    String? mimeType,
  }) async {
    return _analyze(
      imageBytes: imageBytes,
      prompt: prompt,
      mimeType: mimeType ?? 'image/jpeg',
    );
  }

  Future<GeminiVisionResult> analyzeImageFile({
    required File imageFile,
    required String prompt,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return _analyze(
      imageBytes: bytes,
      prompt: prompt,
      mimeType: _mimeTypeFromPath(imageFile.path),
    );
  }

  Future<GeminiVisionResult> _analyze({
    required Uint8List imageBytes,
    required String prompt,
    required String mimeType,
  }) async {
    if (!isConfigured) {
      throw Exception('Backend vision endpoint is not configured.');
    }

    final response = await _apiService.post(
      ApiEndpoints.analyze,
      data: {
        'image': base64Encode(imageBytes),
        'prompt': prompt,
        'image_mime': mimeType,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final description =
        (data['description'] as String? ?? data['response'] as String? ?? '')
            .trim();
    final inferenceMs = (data['inferenceTimeMs'] as num?)?.toInt() ?? 0;
    final model =
        (data['model'] as String? ?? data['engine'] as String? ?? 'backend')
            .trim();

    return GeminiVisionResult(
      description: description.isEmpty
          ? 'No scene description returned.'
          : description,
      objects: _parseObjects(data['detectedObjects']),
      promptTokens: (data['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (data['completionTokens'] as num?)?.toInt() ?? 0,
      inferenceTime: Duration(milliseconds: inferenceMs),
      model: model,
    );
  }

  List<DetectedObject> _parseObjects(dynamic objectsData) {
    if (objectsData is! List<dynamic>) {
      return const [];
    }

    final objects = <DetectedObject>[];
    for (final item in objectsData) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final label =
          (item['label'] as String? ?? item['object'] as String? ?? '').trim();
      if (label.isEmpty) {
        continue;
      }

      final box = _parseBoundingBox(item['box_2d']);
      final boundingBox =
          box ?? const BoundingBox(x: 0.4, y: 0.4, width: 0.2, height: 0.2);

      objects.add(
        DetectedObject(
          label: label,
          confidence: ((item['confidence'] as num?)?.toDouble() ?? 0.7).clamp(
            0.0,
            1.0,
          ),
          boundingBox: boundingBox,
          clockPosition: _toClockPosition(boundingBox),
        ),
      );
    }
    return objects;
  }

  BoundingBox? _parseBoundingBox(dynamic rawBox) {
    if (rawBox is! List<dynamic> || rawBox.length != 4) {
      return null;
    }

    final values = rawBox.map((value) => (value as num).toDouble()).toList();
    final yMin = values[0].clamp(0.0, 1000.0);
    final xMin = values[1].clamp(0.0, 1000.0);
    final yMax = values[2].clamp(0.0, 1000.0);
    final xMax = values[3].clamp(0.0, 1000.0);

    if (xMax <= xMin || yMax <= yMin) {
      return null;
    }

    return BoundingBox(
      x: xMin / 1000,
      y: yMin / 1000,
      width: (xMax - xMin) / 1000,
      height: (yMax - yMin) / 1000,
    );
  }

  ClockPosition _toClockPosition(BoundingBox box) {
    final centerX = box.centerX;
    final dx = centerX - 0.5;
    final hour = (((dx + 0.5) * 12).round()).clamp(1, 12);
    if (hour == 12) {
      return const ClockPosition(12, 'directly ahead');
    }
    if (hour <= 2 || hour == 3) {
      return ClockPosition(hour, 'to your right');
    }
    if (hour >= 9) {
      return ClockPosition(hour, 'to your left');
    }
    return ClockPosition(hour, 'at $hour o\'clock');
  }

  String _mimeTypeFromPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.heic')) return 'image/heic';
    if (lowerPath.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
