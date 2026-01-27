import 'detected_object.dart';

/// Result from vision analysis
class VisionResult {
  /// Human-readable description of the scene
  final String description;
  
  /// List of detected objects
  final List<DetectedObject> objects;
  
  /// Time taken to process the vision analysis
  final Duration processingTime;
  
  /// Whether the local model was used (vs backend)
  final bool usedLocalModel;
  
  const VisionResult({
    required this.description,
    required this.objects,
    required this.processingTime,
    required this.usedLocalModel,
  });
  
  @override
  String toString() =>
      'VisionResult(description: $description, objects: ${objects.length}, '
      'processingTime: ${processingTime.inMilliseconds}ms, local: $usedLocalModel)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionResult &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          objects == other.objects &&
          processingTime == other.processingTime &&
          usedLocalModel == other.usedLocalModel;
  
  @override
  int get hashCode =>
      description.hashCode ^
      objects.hashCode ^
      processingTime.hashCode ^
      usedLocalModel.hashCode;
}
