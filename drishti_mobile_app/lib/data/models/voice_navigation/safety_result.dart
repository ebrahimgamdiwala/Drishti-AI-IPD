import 'hazard.dart';

/// Result from safety hazard detection
class SafetyResult {
  /// Whether any danger was detected
  final bool hasDanger;
  
  /// List of detected hazards
  final List<Hazard> hazards;
  
  /// Warning message to be spoken to the user
  final String warningMessage;
  
  const SafetyResult({
    required this.hasDanger,
    required this.hazards,
    required this.warningMessage,
  });
  
  /// Create a safe result (no hazards)
  const SafetyResult.safe()
      : hasDanger = false,
        hazards = const [],
        warningMessage = '';
  
  @override
  String toString() =>
      'SafetyResult(hasDanger: $hasDanger, hazards: ${hazards.length}, '
      'message: $warningMessage)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyResult &&
          runtimeType == other.runtimeType &&
          hasDanger == other.hasDanger &&
          hazards == other.hazards &&
          warningMessage == other.warningMessage;
  
  @override
  int get hashCode =>
      hasDanger.hashCode ^ hazards.hashCode ^ warningMessage.hashCode;
}
