/// Intent Classifier
///
/// Classifies voice commands into structured intents with confidence scoring.
library;

import '../../models/voice_navigation/voice_navigation_models.dart';

/// Classifier for voice commands
///
/// This classifier analyzes natural language commands and maps them to
/// structured intent types with confidence scores and extracted parameters.
class IntentClassifier {
  /// Classify a voice command into an intent
  ///
  /// Returns a [ClassifiedIntent] with the detected intent type, confidence score,
  /// and any extracted parameters.
  Future<ClassifiedIntent> classify(String command) async {
    // Normalize command: lowercase, trim, and collapse multiple spaces
    final normalizedCommand = command
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Replace multiple spaces with single space
    
    // Handle empty commands
    if (normalizedCommand.isEmpty) {
      return ClassifiedIntent(
        type: IntentType.system,
        confidence: 0.0,
        parameters: {},
        originalCommand: command,
      );
    }
    
    // Calculate confidence scores for all intent types
    final scores = <IntentType, double>{};
    for (final intentType in IntentType.values) {
      scores[intentType] = _calculateConfidence(normalizedCommand, intentType);
    }
    
    // Find the intent type with the highest confidence
    IntentType bestIntent = IntentType.system;
    double bestConfidence = 0.0;
    
    for (final entry in scores.entries) {
      if (entry.value > bestConfidence) {
        bestConfidence = entry.value;
        bestIntent = entry.key;
      }
    }
    
    // Extract parameters for the best matching intent
    final parameters = _extractParameters(normalizedCommand, bestIntent);
    
    return ClassifiedIntent(
      type: bestIntent,
      confidence: bestConfidence,
      parameters: parameters,
      originalCommand: command,
    );
  }

  /// Get intent patterns for matching
  ///
  /// Returns a map of intent types to their matching patterns.
  Map<IntentType, List<String>> _getIntentPatterns() {
    return {
      IntentType.navigation: [
        'go to',
        'open',
        'navigate to',
        'show me',
        'take me to',
        'go back',
        'back',
        'home',
        'main screen',
        'switch to',
        'change to',
      ],
      IntentType.vision: [
        'what',
        'describe',
        'see',
        'look',
        'scan',
        'analyze',
        'in front',
        'ahead',
        'obstacle',
        'around me',
        'tell me more',
        'more',
        'else',
        'read',
        'text',
      ],
      IntentType.relative: [
        'who',
        'is',
        'near',
        'nearby',
        'close',
        'recognize',
        'identify person',
        'add relative',
        'create relative',
        'new relative',
        'add family',
        'save person',
        'remember person',
        'delete relative',
        'remove relative',
        'edit relative',
        'update relative',
        'show all relatives',
        'list relatives',
      ],
      IntentType.auth: [
        'sign in',
        'log in',
        'sign up',
        'register',
        'log out',
        'sign out',
        'create account',
        'account',
      ],
      IntentType.settings: [
        'volume',
        'louder',
        'quieter',
        'speed',
        'faster',
        'slower',
        'language',
        'vibration',
        'haptic',
        'emergency contact',
        'change theme',
        'toggle theme',
        'switch theme',
        'dark mode',
        'light mode',
        'enable',
        'disable',
        'turn on',
        'turn off',
        'select',
        'choose',
        'pick',
        'set',
      ],
      IntentType.system: [
        'battery',
        'connection',
        'connected',
        'online',
        'offline',
        'status',
        'refresh',
        'reload',
        'update',
      ],
      IntentType.emergency: [
        'help',
        'emergency',
        'urgent',
        'call',
        'sos',
      ],
    };
  }

  /// Calculate confidence score for a command matching an intent type
  ///
  /// Returns a score between 0.0 and 1.0.
  double _calculateConfidence(String command, IntentType type) {
    final patterns = _getIntentPatterns()[type] ?? [];
    
    if (patterns.isEmpty) {
      return 0.0;
    }
    
    // Count how many patterns match and track match quality
    int matchCount = 0;
    int bestMatchLength = 0;
    double totalMatchQuality = 0.0;
    
    for (final pattern in patterns) {
      if (command.contains(pattern)) {
        matchCount++;
        // Track the longest matching pattern for better confidence
        if (pattern.length > bestMatchLength) {
          bestMatchLength = pattern.length;
        }
        // Calculate match quality (how much of the command is the pattern)
        totalMatchQuality += pattern.length / command.length;
      }
    }
    
    if (matchCount == 0) {
      return 0.0;
    }
    
    // Base confidence: start high if we have any match
    double confidence = 0.65;
    
    // Boost for match quality (how much of the command is covered by patterns)
    final avgMatchQuality = totalMatchQuality / matchCount;
    confidence += avgMatchQuality * 0.2;
    
    // Boost for multiple pattern matches
    if (matchCount > 1) {
      confidence += 0.1;
    }
    
    // Apply intent-specific boosts
    confidence = _applyIntentSpecificBoosts(command, type, confidence);
    
    // Ensure confidence is between 0.0 and 1.0
    return confidence.clamp(0.0, 1.0);
  }

  /// Apply intent-specific confidence boosts
  double _applyIntentSpecificBoosts(
    String command,
    IntentType type,
    double baseConfidence,
  ) {
    double confidence = baseConfidence;
    
    // Emergency intents get a significant boost for urgency keywords
    if (type == IntentType.emergency) {
      if (command.contains('help') || command.contains('emergency') || command.contains('sos')) {
        // Don't boost if it's "emergency contact" without "call" (that's a settings command)
        if (!command.contains('emergency contact') || command.contains('call')) {
          confidence += 0.15;
        }
      }
      // Boost for "call" in emergency context
      if (command.contains('call') && (command.contains('emergency') || command.contains('help'))) {
        confidence += 0.20;
      }
    }
    
    // Navigation intents get a boost if they mention screen names
    if (type == IntentType.navigation) {
      final screenNames = [
        'settings',
        'dashboard',
        'home',
        'profile',
        'relatives',
        'family',
        'activity',
        'history',
        'vision',
        'camera',
      ];
      for (final screen in screenNames) {
        if (command.contains(screen)) {
          confidence += 0.1;
          break;
        }
      }
    }
    
    // Vision intents get a boost for question words
    if (type == IntentType.vision) {
      if (command.startsWith('what') || command.startsWith('describe') || command.startsWith('tell')) {
        confidence += 0.1;
      }
    }
    
    // Relative intents get a boost for person-related words
    if (type == IntentType.relative) {
      final personWords = ['father', 'mother', 'brother', 'sister', 'family'];
      for (final word in personWords) {
        if (command.contains(word)) {
          confidence += 0.1;
          break;
        }
      }
    }
    
    // Auth intents get a boost for exact phrase matches
    if (type == IntentType.auth) {
      if (command.contains('sign in') || command.contains('sign up') || 
          command.contains('log in') || command.contains('log out') ||
          command.contains('create account') || command.contains('register')) {
        confidence += 0.25;
      }
    }
    
    // Settings intents get a boost for specific setting words
    if (type == IntentType.settings) {
      final settingWords = ['volume', 'language', 'vibration', 'speed', 'louder', 'quieter', 'faster', 'slower'];
      for (final word in settingWords) {
        if (command.contains(word)) {
          confidence += 0.25;
          break;
        }
      }
      // Special boost for "emergency contact" which should be settings, not emergency
      // But only if it's not "call emergency contact" (that's an actual emergency)
      if (command.contains('emergency contact') && !command.contains('call')) {
        confidence += 0.30;
      }
    }
    
    // System intents get a boost for status words
    if (type == IntentType.system) {
      if (command.contains('battery') || command.contains('status') || command.contains('connection')) {
        confidence += 0.15;
      }
    }
    
    return confidence;
  }

  /// Extract parameters from a command for a given intent type
  ///
  /// Returns a map of parameter names to values.
  Map<String, dynamic> _extractParameters(String command, IntentType type) {
    final parameters = <String, dynamic>{};
    
    switch (type) {
      case IntentType.navigation:
        parameters.addAll(_extractNavigationParameters(command));
        break;
      case IntentType.vision:
        parameters.addAll(_extractVisionParameters(command));
        break;
      case IntentType.relative:
        parameters.addAll(_extractRelativeParameters(command));
        break;
      case IntentType.settings:
        parameters.addAll(_extractSettingsParameters(command));
        break;
      case IntentType.auth:
        parameters.addAll(_extractAuthParameters(command));
        break;
      case IntentType.system:
        parameters.addAll(_extractSystemParameters(command));
        break;
      case IntentType.emergency:
        parameters.addAll(_extractEmergencyParameters(command));
        break;
    }
    
    return parameters;
  }

  /// Extract navigation parameters (screen name)
  Map<String, dynamic> _extractNavigationParameters(String command) {
    final parameters = <String, dynamic>{};
    
    // Screen name mappings
    final screenMappings = {
      'settings': '/settings',
      'setting': '/settings',
      'dashboard': '/dashboard',
      'home': '/home',
      'profile': '/profile',
      'relatives': '/relatives',
      'family': '/relatives',
      'activity': '/activity',
      'history': '/activity',
      'vision': '/vision',
      'camera': '/vision',
    };
    
    // Check for screen names in command
    for (final entry in screenMappings.entries) {
      if (command.contains(entry.key)) {
        parameters['screen'] = entry.key;
        parameters['route'] = entry.value;
        break;
      }
    }
    
    // Check for back/home commands
    if (command.contains('back')) {
      parameters['action'] = 'back';
    } else if (command.contains('home') || command.contains('main screen')) {
      parameters['screen'] = 'home';
      parameters['route'] = '/home';
      parameters['action'] = 'home';
    }
    
    return parameters;
  }

  /// Extract vision parameters (analysis type)
  Map<String, dynamic> _extractVisionParameters(String command) {
    final parameters = <String, dynamic>{};
    
    // Determine analysis type
    if (command.contains('obstacle')) {
      parameters['analysisType'] = 'obstacles';
    } else if (command.contains('read') || command.contains('text')) {
      parameters['analysisType'] = 'text';
    } else if (command.contains('scan') || command.contains('surroundings')) {
      parameters['analysisType'] = 'general';
    } else {
      parameters['analysisType'] = 'general';
    }
    
    // Check for follow-up questions
    if (command.contains('tell me more') || command.contains('more details')) {
      parameters['isFollowUp'] = true;
    } else if (command.contains('what else')) {
      parameters['isFollowUp'] = true;
      parameters['requestAlternative'] = true;
    } else {
      parameters['isFollowUp'] = false;
    }
    
    return parameters;
  }

  /// Extract relative identification parameters (person name)
  Map<String, dynamic> _extractRelativeParameters(String command) {
    final parameters = <String, dynamic>{};
    
    // Check for CRUD operations
    if (command.contains('add') || command.contains('create') || command.contains('new')) {
      parameters['action'] = 'create';
    } else if (command.contains('delete') || command.contains('remove')) {
      parameters['action'] = 'delete';
    } else if (command.contains('edit') || command.contains('update')) {
      parameters['action'] = 'edit';
    } else if (command.contains('list') || command.contains('show all')) {
      parameters['action'] = 'list';
    }
    
    // Extract person references
    final personWords = ['father', 'mother', 'brother', 'sister', 'family', 'relative'];
    for (final person in personWords) {
      if (command.contains(person)) {
        parameters['person'] = person;
        break;
      }
    }
    
    // Check for proximity queries
    if (command.contains('near') || command.contains('nearby') || command.contains('close')) {
      parameters['queryType'] = 'proximity';
    } else {
      parameters['queryType'] = 'identification';
    }
    
    return parameters;
  }

  /// Extract settings parameters (setting type and direction)
  Map<String, dynamic> _extractSettingsParameters(String command) {
    final parameters = <String, dynamic>{};
    
    // Volume settings
    if (command.contains('volume') || command.contains('louder') || command.contains('quieter')) {
      parameters['setting'] = 'volume';
      if (command.contains('increase') || command.contains('louder') || command.contains('up')) {
        parameters['direction'] = 'up';
      } else if (command.contains('decrease') || command.contains('quieter') || command.contains('down')) {
        parameters['direction'] = 'down';
      }
    }
    
    // Speech speed settings
    if (command.contains('speed') || command.contains('faster') || command.contains('slower')) {
      parameters['setting'] = 'speechRate';
      if (command.contains('increase') || command.contains('faster')) {
        parameters['direction'] = 'faster';
      } else if (command.contains('decrease') || command.contains('slower')) {
        parameters['direction'] = 'slower';
      }
    }
    
    // Theme settings
    if (command.contains('theme') || command.contains('dark mode') || command.contains('light mode')) {
      parameters['setting'] = 'theme';
      if (command.contains('dark')) {
        parameters['value'] = 'dark';
      } else if (command.contains('light')) {
        parameters['value'] = 'light';
      } else {
        parameters['action'] = 'toggle';
      }
    }
    
    // Language settings
    if (command.contains('language')) {
      parameters['setting'] = 'language';
    }
    
    // Vibration settings
    if (command.contains('vibration') || command.contains('haptic')) {
      parameters['setting'] = 'vibration';
      if (command.contains('disable') || command.contains('turn off')) {
        parameters['action'] = 'disable';
      } else if (command.contains('enable') || command.contains('on') || command.contains('turn on')) {
        parameters['action'] = 'enable';
      } else {
        parameters['action'] = 'toggle';
      }
    }
    
    // Emergency contact settings
    if (command.contains('emergency contact')) {
      parameters['setting'] = 'emergencyContact';
      parameters['action'] = 'set';
    }
    
    // Generic selection commands
    if (command.contains('select') || command.contains('choose') || command.contains('pick')) {
      parameters['action'] = 'select';
      // Try to extract what to select (first, second, third, etc.)
      if (command.contains('first')) {
        parameters['index'] = 0;
      } else if (command.contains('second')) {
        parameters['index'] = 1;
      } else if (command.contains('third')) {
        parameters['index'] = 2;
      } else if (command.contains('fourth')) {
        parameters['index'] = 3;
      } else if (command.contains('fifth')) {
        parameters['index'] = 4;
      }
    }
    
    return parameters;
  }

  /// Extract authentication parameters (auth action)
  Map<String, dynamic> _extractAuthParameters(String command) {
    final parameters = <String, dynamic>{};
    
    if (command.contains('sign in') || command.contains('log in')) {
      parameters['action'] = 'signIn';
    } else if (command.contains('sign up') || command.contains('register') || command.contains('create account')) {
      parameters['action'] = 'signUp';
    } else if (command.contains('sign out') || command.contains('log out')) {
      parameters['action'] = 'signOut';
    }
    
    return parameters;
  }

  /// Extract system parameters (info type)
  Map<String, dynamic> _extractSystemParameters(String command) {
    final parameters = <String, dynamic>{};
    
    if (command.contains('battery')) {
      parameters['infoType'] = 'battery';
    } else if (command.contains('connection') || command.contains('connected') || 
               command.contains('online') || command.contains('offline') ||
               command.contains('network')) {
      parameters['infoType'] = 'connection';
    } else {
      parameters['infoType'] = 'status';
    }
    
    return parameters;
  }

  /// Extract emergency parameters
  Map<String, dynamic> _extractEmergencyParameters(String command) {
    final parameters = <String, dynamic>{};
    
    if (command.contains('call')) {
      parameters['action'] = 'call';
    } else {
      parameters['action'] = 'activate';
    }
    
    return parameters;
  }
}
