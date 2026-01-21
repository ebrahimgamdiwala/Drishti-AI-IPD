/// Drishti App - Alert Model
/// 
/// Alert data model for safety notifications.
library;

enum AlertType {
  closeCall('close-call'),
  lifeThreat('life-threat'),
  obstacle('obstacle'),
  warning('warning'),
  info('info');

  final String value;
  const AlertType(this.value);

  static AlertType fromString(String? value) {
    return AlertType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertType.info,
    );
  }
}

enum AlertSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  final String value;
  const AlertSeverity(this.value);

  static AlertSeverity fromString(String? value) {
    return AlertSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertSeverity.medium,
    );
  }
}

class AlertModel {
  final String id;
  final String userId;
  final AlertType type;
  final AlertSeverity severity;
  final String description;
  final String? imageRef;
  final List<DetectedObject> detectedObjects;
  final bool acknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    this.type = AlertType.info,
    this.severity = AlertSeverity.medium,
    required this.description,
    this.imageRef,
    this.detectedObjects = const [],
    this.acknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: AlertType.fromString(json['type']),
      severity: AlertSeverity.fromString(json['severity']),
      description: json['description'] ?? '',
      imageRef: json['image_ref'],
      detectedObjects: (json['detected_objects'] as List<dynamic>?)
          ?.map((e) => DetectedObject.fromJson(e))
          .toList() ?? [],
      acknowledged: json['acknowledged'] ?? false,
      acknowledgedBy: json['acknowledged_by'],
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'severity': severity.value,
      'description': description,
      'image_ref': imageRef,
      'detected_objects': detectedObjects.map((e) => e.toJson()).toList(),
      'acknowledged': acknowledged,
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DetectedObject {
  final String object;
  final double confidence;
  final String distance;

  DetectedObject({
    required this.object,
    this.confidence = 0.0,
    this.distance = 'unknown',
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      object: json['object'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      distance: json['distance'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'confidence': confidence,
      'distance': distance,
    };
  }
}
