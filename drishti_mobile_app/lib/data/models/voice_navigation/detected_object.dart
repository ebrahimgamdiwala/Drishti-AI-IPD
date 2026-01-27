import 'bounding_box.dart';
import 'clock_position.dart';

/// Detected object from vision analysis
class DetectedObject {
  /// Object label (e.g., "car", "person", "stairs")
  final String label;
  
  /// Confidence score (0.0-1.0)
  final double confidence;
  
  /// Bounding box coordinates
  final BoundingBox boundingBox;
  
  /// Clock position for describing location
  final ClockPosition clockPosition;
  
  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.clockPosition,
  });
  
  @override
  String toString() =>
      'DetectedObject(label: $label, confidence: $confidence, position: $clockPosition)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedObject &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          confidence == other.confidence &&
          boundingBox == other.boundingBox &&
          clockPosition == other.clockPosition;
  
  @override
  int get hashCode =>
      label.hashCode ^
      confidence.hashCode ^
      boundingBox.hashCode ^
      clockPosition.hashCode;
}
