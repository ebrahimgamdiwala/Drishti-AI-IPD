import 'clock_position.dart';
import 'hazard_level.dart';

/// Detected hazard from safety analysis
class Hazard {
  /// Type of hazard (e.g., "vehicle", "stairs", "hole", "obstacle")
  final String type;
  
  /// Severity level of the hazard
  final HazardLevel level;
  
  /// Position of the hazard using clock directions
  final ClockPosition position;
  
  /// Estimated distance in meters
  final double distance;
  
  const Hazard({
    required this.type,
    required this.level,
    required this.position,
    required this.distance,
  });
  
  @override
  String toString() =>
      'Hazard(type: $type, level: $level, position: $position, distance: ${distance}m)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hazard &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          level == other.level &&
          position == other.position &&
          distance == other.distance;
  
  @override
  int get hashCode =>
      type.hashCode ^ level.hashCode ^ position.hashCode ^ distance.hashCode;
}
