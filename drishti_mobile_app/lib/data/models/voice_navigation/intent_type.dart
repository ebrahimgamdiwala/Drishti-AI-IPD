/// Intent Type Enumeration
///
/// Defines the seven types of intents that can be classified from voice commands.
library;

/// The type of intent classified from a voice command
enum IntentType {
  /// Navigation commands (go to screen, go back, home)
  navigation,

  /// Vision analysis commands (scan, what's in front, obstacles)
  vision,

  /// Relative identification commands (who is near, is X nearby)
  relative,

  /// Authentication commands (sign in, sign up, log out)
  auth,

  /// Settings adjustment commands (volume, language, vibration)
  settings,

  /// System information commands (battery, connection status)
  system,

  /// Emergency commands (help, emergency, call contact)
  emergency,
}

/// Extension methods for IntentType
extension IntentTypeExtension on IntentType {
  /// Get the display name for this intent type
  String get displayName {
    switch (this) {
      case IntentType.navigation:
        return 'Navigation';
      case IntentType.vision:
        return 'Vision';
      case IntentType.relative:
        return 'Relative';
      case IntentType.auth:
        return 'Authentication';
      case IntentType.settings:
        return 'Settings';
      case IntentType.system:
        return 'System';
      case IntentType.emergency:
        return 'Emergency';
    }
  }

  /// Get the priority level for this intent type (higher = more urgent)
  int get priority {
    switch (this) {
      case IntentType.emergency:
        return 100; // Highest priority
      case IntentType.vision:
        return 50; // High priority for safety
      case IntentType.navigation:
        return 30;
      case IntentType.auth:
        return 30;
      case IntentType.settings:
        return 20;
      case IntentType.system:
        return 10;
      case IntentType.relative:
        return 10;
    }
  }
}
