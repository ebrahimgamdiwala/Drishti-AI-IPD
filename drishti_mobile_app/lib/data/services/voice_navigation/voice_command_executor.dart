/// Voice Command Executor
///
/// Executes voice commands for all app features and settings.
library;

import 'package:flutter/foundation.dart';
import 'audio_feedback_engine.dart';

/// Enum for feature actions
enum FeatureAction {
  // Vision features
  scan,
  readText,
  detectObstacles,
  identifyPeople,
  analyzeScene,
  getDescription,

  // Relatives features
  addRelative,
  listRelatives,
  findRelative,
  editRelative,
  deleteRelative,

  // Settings
  adjustVolume,
  adjustSpeechRate,
  toggleVibration,
  toggleNotifications,
  changeLanguage,

  // Activity
  viewActivity,
  clearActivity,
  filterActivity,

  // Dashboard
  viewStats,
  viewBattery,
  viewConnection,
  viewAlerts,

  // Favorites
  addFavorite,
  listFavorites,
  removeFavorite,
  accessFavorite,

  // Emergency
  callEmergencyContact,
  sendAlert,

  // Navigation
  goHome,
  goDashboard,
  goVision,
  goRelatives,
  goSettings,
  goActivity,
  goProfile,

  // General
  help,
  about,
  logout,
  unknown,
}

/// Voice command configuration for features
class VoiceCommandConfig {
  static const Map<String, FeatureAction> commandMap = {
    // Vision commands
    'scan': FeatureAction.scan,
    'scan surroundings': FeatureAction.scan,
    'scan around': FeatureAction.scan,
    'what is in front': FeatureAction.scan,
    'what do you see': FeatureAction.analyzeScene,
    'describe the scene': FeatureAction.analyzeScene,
    'read text': FeatureAction.readText,
    'read the text': FeatureAction.readText,
    'detect obstacles': FeatureAction.detectObstacles,
    'are there obstacles': FeatureAction.detectObstacles,
    'obstacles ahead': FeatureAction.detectObstacles,
    'identify people': FeatureAction.identifyPeople,
    'who is here': FeatureAction.identifyPeople,
    'recognize person': FeatureAction.identifyPeople,

    // Relatives commands
    'add relative': FeatureAction.addRelative,
    'add family member': FeatureAction.addRelative,
    'new relative': FeatureAction.addRelative,
    'list relatives': FeatureAction.listRelatives,
    'show relatives': FeatureAction.listRelatives,
    'my relatives': FeatureAction.listRelatives,
    'family members': FeatureAction.listRelatives,
    'find relative': FeatureAction.findRelative,
    'where is': FeatureAction.findRelative,
    'edit relative': FeatureAction.editRelative,
    'update relative': FeatureAction.editRelative,
    'delete relative': FeatureAction.deleteRelative,
    'remove relative': FeatureAction.deleteRelative,

    // Settings commands
    'increase volume': FeatureAction.adjustVolume,
    'decrease volume': FeatureAction.adjustVolume,
    'faster speech': FeatureAction.adjustSpeechRate,
    'slower speech': FeatureAction.adjustSpeechRate,
    'toggle vibration': FeatureAction.toggleVibration,
    'toggle notifications': FeatureAction.toggleNotifications,
    'change language': FeatureAction.changeLanguage,

    // Activity commands
    'show activity': FeatureAction.viewActivity,
    'activity history': FeatureAction.viewActivity,
    'clear activity': FeatureAction.clearActivity,
    'filter activity': FeatureAction.filterActivity,

    // Dashboard commands
    'show stats': FeatureAction.viewStats,
    'statistics': FeatureAction.viewStats,
    'battery status': FeatureAction.viewBattery,
    'check battery': FeatureAction.viewBattery,
    'connection status': FeatureAction.viewConnection,
    'network status': FeatureAction.viewConnection,
    'show alerts': FeatureAction.viewAlerts,
    'alerts': FeatureAction.viewAlerts,

    // Favorites commands
    'add favorite': FeatureAction.addFavorite,
    'save favorite': FeatureAction.addFavorite,
    'list favorites': FeatureAction.listFavorites,
    'show favorites': FeatureAction.listFavorites,
    'my favorites': FeatureAction.listFavorites,
    'remove favorite': FeatureAction.removeFavorite,
    'delete favorite': FeatureAction.removeFavorite,

    // Emergency commands
    'emergency': FeatureAction.callEmergencyContact,
    'call emergency': FeatureAction.callEmergencyContact,
    'help me': FeatureAction.callEmergencyContact,
    'send alert': FeatureAction.sendAlert,
    'alert': FeatureAction.sendAlert,

    // Navigation commands
    'go home': FeatureAction.goHome,
    'home': FeatureAction.goHome,
    'dashboard': FeatureAction.goDashboard,
    'go dashboard': FeatureAction.goDashboard,
    'vision': FeatureAction.goVision,
    'ai vision': FeatureAction.goVision,
    'camera': FeatureAction.goVision,
    'relatives': FeatureAction.goRelatives,
    'family': FeatureAction.goRelatives,
    'settings': FeatureAction.goSettings,
    'activity': FeatureAction.goActivity,
    'history': FeatureAction.goActivity,
    'profile': FeatureAction.goProfile,
    'my profile': FeatureAction.goProfile,

    // General commands
    'help': FeatureAction.help,
    'show help': FeatureAction.help,
    'about': FeatureAction.about,
    'about app': FeatureAction.about,
    'logout': FeatureAction.logout,
    'sign out': FeatureAction.logout,
  };

  /// Get feature action from command
  static FeatureAction getActionFromCommand(String command) {
    final normalized = command.toLowerCase().trim();
    return commandMap[normalized] ?? FeatureAction.unknown;
  }

  /// Get all available commands
  static List<String> getAllCommands() {
    return commandMap.keys.toList();
  }
}

/// Voice Command Executor
class VoiceCommandExecutor {
  final AudioFeedbackEngine _audioFeedback;

  // Callbacks for various features
  final Function(FeatureAction, Map<String, dynamic>)? _onFeatureAction;
  final Function(String route)? _onNavigate;

  VoiceCommandExecutor({
    required AudioFeedbackEngine audioFeedback,
    Function(FeatureAction, Map<String, dynamic>)? onFeatureAction,
    Function(String)? onNavigate,
  }) : _audioFeedback = audioFeedback,
       _onFeatureAction = onFeatureAction,
       _onNavigate = onNavigate;

  /// Execute a voice command
  Future<void> executeCommand(String command) async {
    final action = VoiceCommandConfig.getActionFromCommand(command);

    debugPrint(
      '[VoiceCommandExecutor] Executing command: "$command" → $action',
    );

    switch (action) {
      // Vision features
      case FeatureAction.scan:
        await _executeScan();
      case FeatureAction.readText:
        await _executeReadText();
      case FeatureAction.detectObstacles:
        await _executeDetectObstacles();
      case FeatureAction.identifyPeople:
        await _executeIdentifyPeople();
      case FeatureAction.analyzeScene:
        await _executeAnalyzeScene();
      case FeatureAction.getDescription:
        await _executeGetDescription();

      // Relatives features
      case FeatureAction.addRelative:
        await _executeAddRelative();
      case FeatureAction.listRelatives:
        await _executeListRelatives();
      case FeatureAction.findRelative:
        await _executeFindRelative();
      case FeatureAction.editRelative:
        await _executeEditRelative();
      case FeatureAction.deleteRelative:
        await _executeDeleteRelative();

      // Settings
      case FeatureAction.adjustVolume:
        await _executeAdjustVolume(command);
      case FeatureAction.adjustSpeechRate:
        await _executeAdjustSpeechRate(command);
      case FeatureAction.toggleVibration:
        await _executeToggleVibration();
      case FeatureAction.toggleNotifications:
        await _executeToggleNotifications();
      case FeatureAction.changeLanguage:
        await _executeChangeLanguage();

      // Activity
      case FeatureAction.viewActivity:
        await _executeViewActivity();
      case FeatureAction.clearActivity:
        await _executeClearActivity();
      case FeatureAction.filterActivity:
        await _executeFilterActivity();

      // Dashboard
      case FeatureAction.viewStats:
        await _executeViewStats();
      case FeatureAction.viewBattery:
        await _executeViewBattery();
      case FeatureAction.viewConnection:
        await _executeViewConnection();
      case FeatureAction.viewAlerts:
        await _executeViewAlerts();

      // Favorites
      case FeatureAction.addFavorite:
        await _executeAddFavorite();
      case FeatureAction.listFavorites:
        await _executeListFavorites();
      case FeatureAction.removeFavorite:
        await _executeRemoveFavorite();
      case FeatureAction.accessFavorite:
        await _executeAccessFavorite();

      // Emergency
      case FeatureAction.callEmergencyContact:
        await _executeCallEmergency();
      case FeatureAction.sendAlert:
        await _executeSendAlert();

      // Navigation
      case FeatureAction.goHome:
        _onNavigate?.call('/home');
        await _audioFeedback.speak('Going to home');
      case FeatureAction.goDashboard:
        _onNavigate?.call('/dashboard');
        await _audioFeedback.speak('Opening dashboard');
      case FeatureAction.goVision:
        _onNavigate?.call('/vision');
        await _audioFeedback.speak('Opening AI vision');
      case FeatureAction.goRelatives:
        _onNavigate?.call('/relatives');
        await _audioFeedback.speak('Opening relatives');
      case FeatureAction.goSettings:
        _onNavigate?.call('/settings');
        await _audioFeedback.speak('Opening settings');
      case FeatureAction.goActivity:
        _onNavigate?.call('/activity');
        await _audioFeedback.speak('Opening activity history');
      case FeatureAction.goProfile:
        _onNavigate?.call('/profile');
        await _audioFeedback.speak('Opening profile');

      // General
      case FeatureAction.help:
        await _executeShowHelp();
      case FeatureAction.about:
        await _executeShowAbout();
      case FeatureAction.logout:
        await _executeLogout();
      case FeatureAction.unknown:
        await _audioFeedback.speak('Sorry, I did not understand that command');
    }

    // Notify feature action callback if not a navigation
    if (!_isNavigationAction(action)) {
      _onFeatureAction?.call(action, {});
    }
  }

  bool _isNavigationAction(FeatureAction action) {
    return action.name.startsWith('go');
  }

  // Vision implementations
  Future<void> _executeScan() async {
    _onNavigate?.call('/vision');
    await _audioFeedback.speak('Starting scan of your surroundings');
  }

  Future<void> _executeReadText() async {
    _onNavigate?.call('/vision');
    await _audioFeedback.speak(
      'Ready to read text. Point your camera at the text',
    );
  }

  Future<void> _executeDetectObstacles() async {
    _onNavigate?.call('/vision');
    await _audioFeedback.speak('Scanning for obstacles');
  }

  Future<void> _executeIdentifyPeople() async {
    _onNavigate?.call('/vision');
    await _audioFeedback.speak('Identifying people around you');
  }

  Future<void> _executeAnalyzeScene() async {
    _onNavigate?.call('/vision');
    await _audioFeedback.speak('Analyzing your surroundings');
  }

  Future<void> _executeGetDescription() async {
    _onNavigate?.call('/vision');
    await _audioFeedback.speak('Providing detailed description');
  }

  // Relatives implementations
  Future<void> _executeAddRelative() async {
    _onNavigate?.call('/relatives');
    await _audioFeedback.speak('Opening relatives to add a new family member');
  }

  Future<void> _executeListRelatives() async {
    _onNavigate?.call('/relatives');
    await _audioFeedback.speak('Showing your relatives list');
  }

  Future<void> _executeFindRelative() async {
    _onNavigate?.call('/relatives');
    await _audioFeedback.speak('Searching for family member');
  }

  Future<void> _executeEditRelative() async {
    _onNavigate?.call('/relatives');
    await _audioFeedback.speak('Ready to edit family member information');
  }

  Future<void> _executeDeleteRelative() async {
    _onNavigate?.call('/relatives');
    await _audioFeedback.speak('Ready to remove family member');
  }

  // Settings implementations
  Future<void> _executeAdjustVolume(String command) async {
    final direction = command.contains('increase') || command.contains('up')
        ? 'up'
        : 'down';
    await _audioFeedback.speak('Volume $direction');
  }

  Future<void> _executeAdjustSpeechRate(String command) async {
    final direction = command.contains('faster') ? 'faster' : 'slower';
    await _audioFeedback.speak('Speech rate adjusted to $direction');
  }

  Future<void> _executeToggleVibration() async {
    await _audioFeedback.speak('Vibration toggled');
  }

  Future<void> _executeToggleNotifications() async {
    await _audioFeedback.speak('Notifications toggled');
  }

  Future<void> _executeChangeLanguage() async {
    _onNavigate?.call('/settings');
    await _audioFeedback.speak('Opening language settings');
  }

  // Activity implementations
  Future<void> _executeViewActivity() async {
    _onNavigate?.call('/activity');
    await _audioFeedback.speak('Opening activity history');
  }

  Future<void> _executeClearActivity() async {
    await _audioFeedback.speak('Cleared activity history');
  }

  Future<void> _executeFilterActivity() async {
    await _audioFeedback.speak('Opening activity filters');
  }

  // Dashboard implementations
  Future<void> _executeViewStats() async {
    _onNavigate?.call('/dashboard');
    await _audioFeedback.speak('Showing statistics');
  }

  Future<void> _executeViewBattery() async {
    _onNavigate?.call('/dashboard');
    await _audioFeedback.speak('Showing battery status');
  }

  Future<void> _executeViewConnection() async {
    _onNavigate?.call('/dashboard');
    await _audioFeedback.speak('Showing connection status');
  }

  Future<void> _executeViewAlerts() async {
    _onNavigate?.call('/dashboard');
    await _audioFeedback.speak('Showing alerts');
  }

  // Favorites implementations
  Future<void> _executeAddFavorite() async {
    await _audioFeedback.speak('Added to favorites');
  }

  Future<void> _executeListFavorites() async {
    _onNavigate?.call('/settings'); // Or favorites screen
    await _audioFeedback.speak('Opening favorites');
  }

  Future<void> _executeRemoveFavorite() async {
    await _audioFeedback.speak('Removed from favorites');
  }

  Future<void> _executeAccessFavorite() async {
    await _audioFeedback.speak('Accessing favorite');
  }

  // Emergency implementations
  Future<void> _executeCallEmergency() async {
    await _audioFeedback.speakImmediate(
      'EMERGENCY MODE ACTIVATED. Contacting emergency contact immediately',
    );
    // Actual emergency call would be implemented here
  }

  Future<void> _executeSendAlert() async {
    await _audioFeedback.speak('Emergency alert sent to your contacts');
  }

  // General implementations
  Future<void> _executeShowHelp() async {
    await _audioFeedback.speak(
      'Here are some voice commands you can use. Say scan to analyze surroundings, add relative to add family member, show settings to open settings, and more',
    );
  }

  Future<void> _executeShowAbout() async {
    _onNavigate?.call('/about');
    await _audioFeedback.speak(
      'Drishti is an accessibility-first vision companion designed to help you navigate and understand your surroundings',
    );
  }

  Future<void> _executeLogout() async {
    await _audioFeedback.speak('Logging out');
    _onFeatureAction?.call(FeatureAction.logout, {});
  }
}
