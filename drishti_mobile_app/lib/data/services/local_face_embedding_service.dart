/// On-device face embedding generation using TFLite face models.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:face_detection_tflite/face_detection_tflite.dart';

class LocalFaceEmbeddingService {
  static final LocalFaceEmbeddingService _instance =
      LocalFaceEmbeddingService._internal();

  factory LocalFaceEmbeddingService() => _instance;

  LocalFaceEmbeddingService._internal();

  FaceDetector? _detector;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized && _detector != null) {
      return;
    }

    final detector = FaceDetector();
    await detector.initialize(model: FaceDetectionModel.backCamera);
    _detector = detector;
    _initialized = true;
  }

  Future<List<double>?> embeddingFromImageFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await embeddingFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<List<double>?> embeddingFromBytes(Uint8List bytes) async {
    try {
      await _ensureInitialized();
      final detector = _detector;
      if (detector == null) {
        return null;
      }

      final faces = await detector.detectFaces(
        bytes,
        mode: FaceDetectionMode.fast,
      );
      if (faces.isEmpty) {
        return null;
      }

      // Pick the largest face when multiple faces are present.
      Face largest = faces.first;
      double largestArea =
          largest.boundingBox.width * largest.boundingBox.height;
      for (int i = 1; i < faces.length; i++) {
        final candidate = faces[i];
        final area = candidate.boundingBox.width * candidate.boundingBox.height;
        if (area > largestArea) {
          largest = candidate;
          largestArea = area;
        }
      }

      final rawEmbedding = await detector.getFaceEmbedding(largest, bytes);
      if (rawEmbedding.isEmpty) {
        return null;
      }

      final embedding = rawEmbedding
          .map((v) => (v as num).toDouble())
          .toList(growable: false);
      return _l2Normalize(embedding);
    } catch (_) {
      return null;
    }
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    double dot = 0;
    double na = 0;
    double nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na <= 0 || nb <= 0) return 0;
    final cosine = dot / (math.sqrt(na) * math.sqrt(nb));
    return cosine;
  }

  List<double> _l2Normalize(List<double> vector) {
    double norm = 0;
    for (final v in vector) {
      norm += v * v;
    }
    final denom = math.sqrt(norm);
    if (denom < 1e-8) {
      return vector;
    }
    return vector.map((v) => v / denom).toList(growable: false);
  }

  Future<void> dispose() async {
    if (_detector != null) {
      _detector!.dispose();
      _detector = null;
    }
    _initialized = false;
  }
}
