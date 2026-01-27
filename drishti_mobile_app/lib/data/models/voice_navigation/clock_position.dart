/// Clock position for describing object locations using clock directions
/// (e.g., "at 3 o'clock", "directly ahead")
class ClockPosition {
  /// Hour position (1-12)
  final int hour;
  
  /// Human-readable description (e.g., "at 3 o'clock", "directly ahead")
  final String description;
  
  const ClockPosition(this.hour, this.description);
  
  @override
  String toString() => description;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockPosition &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          description == other.description;
  
  @override
  int get hashCode => hour.hashCode ^ description.hashCode;
}
