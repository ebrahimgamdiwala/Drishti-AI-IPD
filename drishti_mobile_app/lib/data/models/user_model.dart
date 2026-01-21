/// Drishti App - User Model
/// 
/// User data model matching FastAPI backend.
library;

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isEmailVerified;
  final String? authProvider;
  final List<EmergencyContact> emergencyContacts;
  final UserSettings settings;
  final List<String> connectedUsers;
  final DateTime? createdAt;
  final DateTime? lastActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isEmailVerified = false,
    this.authProvider,
    this.emergencyContacts = const [],
    UserSettings? settings,
    this.connectedUsers = const [],
    this.createdAt,
    this.lastActive,
  }) : settings = settings ?? UserSettings();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      isEmailVerified: json['is_email_verified'] ?? false,
      authProvider: json['auth_provider'],
      emergencyContacts: (json['emergency_contacts'] as List<dynamic>?)
          ?.map((e) => EmergencyContact.fromJson(e))
          .toList() ?? [],
      settings: json['settings'] != null 
          ? UserSettings.fromJson(json['settings']) 
          : UserSettings(),
      connectedUsers: (json['connected_users'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      lastActive: json['last_active'] != null 
          ? DateTime.tryParse(json['last_active']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'is_email_verified': isEmailVerified,
      'auth_provider': authProvider,
      'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'connected_users': connectedUsers,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isEmailVerified,
    String? authProvider,
    List<EmergencyContact>? emergencyContacts,
    UserSettings? settings,
    List<String>? connectedUsers,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      settings: settings ?? this.settings,
      connectedUsers: connectedUsers ?? this.connectedUsers,
      createdAt: createdAt,
      lastActive: lastActive,
    );
  }
}

class EmergencyContact {
  final String? name;
  final String? email;
  final String? phone;
  final String? relationship;

  EmergencyContact({
    this.name,
    this.email,
    this.phone,
    this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      relationship: json['relationship'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
    };
  }
}

class AlertPreferences {
  final bool emailAlerts;
  final bool criticalOnly;

  AlertPreferences({
    this.emailAlerts = true,
    this.criticalOnly = false,
  });

  factory AlertPreferences.fromJson(Map<String, dynamic> json) {
    return AlertPreferences(
      emailAlerts: json['email_alerts'] ?? true,
      criticalOnly: json['critical_only'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_alerts': emailAlerts,
      'critical_only': criticalOnly,
    };
  }
}

class UserSettings {
  final double voiceSpeed;
  final bool highContrast;
  final bool continuousListening;
  final AlertPreferences alertPreferences;

  UserSettings({
    this.voiceSpeed = 1.0,
    this.highContrast = false,
    this.continuousListening = false,
    AlertPreferences? alertPreferences,
  }) : alertPreferences = alertPreferences ?? AlertPreferences();

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      voiceSpeed: (json['voice_speed'] ?? 1.0).toDouble(),
      highContrast: json['high_contrast'] ?? false,
      continuousListening: json['continuous_listening'] ?? false,
      alertPreferences: json['alert_preferences'] != null
          ? AlertPreferences.fromJson(json['alert_preferences'])
          : AlertPreferences(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_speed': voiceSpeed,
      'high_contrast': highContrast,
      'continuous_listening': continuousListening,
      'alert_preferences': alertPreferences.toJson(),
    };
  }
}
