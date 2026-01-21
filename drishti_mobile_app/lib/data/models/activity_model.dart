/// Drishti App - Activity Model
/// 
/// Activity/history log data model.
library;

enum ActivityType {
  scan,
  voice,
  alert,
  identify,
  login,
  other;

  static ActivityType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'scan':
        return ActivityType.scan;
      case 'voice':
        return ActivityType.voice;
      case 'alert':
        return ActivityType.alert;
      case 'identify':
        return ActivityType.identify;
      case 'login':
        return ActivityType.login;
      default:
        return ActivityType.other;
    }
  }
}

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? severity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.severity,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? '',
      type: ActivityType.fromString(json['type']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
