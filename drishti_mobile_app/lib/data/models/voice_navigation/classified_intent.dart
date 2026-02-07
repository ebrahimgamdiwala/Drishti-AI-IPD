/// Classified Intent Model
///
/// Represents the result of classifying a voice command into a structured intent.
library;

import 'intent_type.dart';

/// A classified intent from a voice command
class ClassifiedIntent {
  /// The type of intent
  final IntentType type;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Extracted parameters from the command
  final Map<String, dynamic> parameters;

  /// The original voice command
  final String originalCommand;

  /// Timestamp when the intent was classified
  final DateTime timestamp;

  ClassifiedIntent({
    required this.type,
    required this.confidence,
    required this.parameters,
    required this.originalCommand,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Whether the confidence score is high enough to act on
  /// (threshold is 0.65 as per requirements)
  bool get isConfident => confidence >= 0.65;

  /// Get the priority of this intent
  int get priority => type.priority;

  /// Create a copy with updated fields
  ClassifiedIntent copyWith({
    IntentType? type,
    double? confidence,
    Map<String, dynamic>? parameters,
    String? originalCommand,
    DateTime? timestamp,
  }) {
    return ClassifiedIntent(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      parameters: parameters ?? this.parameters,
      originalCommand: originalCommand ?? this.originalCommand,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'confidence': confidence,
      'parameters': parameters,
      'originalCommand': originalCommand,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ClassifiedIntent.fromJson(Map<String, dynamic> json) {
    return ClassifiedIntent(
      type: IntentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IntentType.system,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      originalCommand: json['originalCommand'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'ClassifiedIntent(type: ${type.name}, confidence: ${confidence.toStringAsFixed(2)}, '
        'parameters: $parameters, command: "$originalCommand")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClassifiedIntent &&
        other.type == type &&
        other.confidence == confidence &&
        other.originalCommand == originalCommand;
  }

  @override
  int get hashCode {
    return type.hashCode ^ confidence.hashCode ^ originalCommand.hashCode;
  }
}
