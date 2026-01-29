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
  speechFaster,
  speechSlower,
  speechNormal,
  toggleVibration,
  toggleNotifications,
  changeLanguage,
  toggleTheme,
  darkMode,
  lightMode,

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
  viewEmergencyContacts,
  addEmergencyContact,
  sendAlert,

  // Connected Users
  viewConnectedUsers,
  addConnectedUser,

  // Navigation
  goHome,
  goDashboard,
  goVision,
  goRelatives,
  goSettings,
  goActivity,
  goProfile,
  goHelp,
  goEmergency,
  goFavorites,
  goConnectedUsers,
  goBack,

  // General
  help,
  about,
  logout,
  cancel,
  stop,
  repeat,
  unknown,
}

/// Voice command configuration for features
class VoiceCommandConfig {
  static const Map<String, FeatureAction> commandMap = {
    // Vision commands
    'scan': FeatureAction.scan,
    'scan surroundings': FeatureAction.scan,
    'scan around': FeatureAction.scan,
    'scan area': FeatureAction.scan,
    'what is in front': FeatureAction.scan,
    'what is around me': FeatureAction.scan,
    'what do you see': FeatureAction.analyzeScene,
    'describe the scene': FeatureAction.analyzeScene,
    'describe surroundings': FeatureAction.analyzeScene,
    'analyze scene': FeatureAction.analyzeScene,
    'read text': FeatureAction.readText,
    'read the text': FeatureAction.readText,
    'read this': FeatureAction.readText,
    'ocr': FeatureAction.readText,
    'detect obstacles': FeatureAction.detectObstacles,
    'are there obstacles': FeatureAction.detectObstacles,
    'obstacles ahead': FeatureAction.detectObstacles,
    'check path': FeatureAction.detectObstacles,
    'identify people': FeatureAction.identifyPeople,
    'who is here': FeatureAction.identifyPeople,
    'who is there': FeatureAction.identifyPeople,
    'recognize person': FeatureAction.identifyPeople,
    'recognize face': FeatureAction.identifyPeople,

    // Relatives commands
    'add relative': FeatureAction.addRelative,
    'add family member': FeatureAction.addRelative,
    'new relative': FeatureAction.addRelative,
    'add new relative': FeatureAction.addRelative,
    'create relative': FeatureAction.addRelative,
    'list relatives': FeatureAction.listRelatives,
    'show relatives': FeatureAction.listRelatives,
    'my relatives': FeatureAction.listRelatives,
    'family members': FeatureAction.listRelatives,
    'view relatives': FeatureAction.listRelatives,
    'find relative': FeatureAction.findRelative,
    'search relative': FeatureAction.findRelative,
    'where is': FeatureAction.findRelative,
    'edit relative': FeatureAction.editRelative,
    'update relative': FeatureAction.editRelative,
    'modify relative': FeatureAction.editRelative,
    'delete relative': FeatureAction.deleteRelative,
    'remove relative': FeatureAction.deleteRelative,

    // Speech speed commands
    'speak faster': FeatureAction.speechFaster,
    'faster speech': FeatureAction.speechFaster,
    'talk faster': FeatureAction.speechFaster,
    'speed up': FeatureAction.speechFaster,
    'increase speed': FeatureAction.speechFaster,
    'speak slower': FeatureAction.speechSlower,
    'slower speech': FeatureAction.speechSlower,
    'talk slower': FeatureAction.speechSlower,
    'slow down': FeatureAction.speechSlower,
    'decrease speed': FeatureAction.speechSlower,
    'normal speed': FeatureAction.speechNormal,
    'reset speed': FeatureAction.speechNormal,
    'default speed': FeatureAction.speechNormal,

    // Volume commands
    'increase volume': FeatureAction.adjustVolume,
    'volume up': FeatureAction.adjustVolume,
    'louder': FeatureAction.adjustVolume,
    'decrease volume': FeatureAction.adjustVolume,
    'volume down': FeatureAction.adjustVolume,
    'quieter': FeatureAction.adjustVolume,

    // Theme commands
    'toggle theme': FeatureAction.toggleTheme,
    'switch theme': FeatureAction.toggleTheme,
    'change theme': FeatureAction.toggleTheme,
    'dark mode': FeatureAction.darkMode,
    'enable dark mode': FeatureAction.darkMode,
    'turn on dark mode': FeatureAction.darkMode,
    'light mode': FeatureAction.lightMode,
    'enable light mode': FeatureAction.lightMode,
    'turn on light mode': FeatureAction.lightMode,

    // Other settings commands
    'toggle vibration': FeatureAction.toggleVibration,
    'toggle notifications': FeatureAction.toggleNotifications,
    'change language': FeatureAction.changeLanguage,

    // Activity commands
    'show activity': FeatureAction.viewActivity,
    'activity history': FeatureAction.viewActivity,
    'view activity': FeatureAction.viewActivity,
    'recent activity': FeatureAction.viewActivity,
    'clear activity': FeatureAction.clearActivity,
    'delete history': FeatureAction.clearActivity,
    'filter activity': FeatureAction.filterActivity,

    // Dashboard commands
    'show stats': FeatureAction.viewStats,
    'statistics': FeatureAction.viewStats,
    'show statistics': FeatureAction.viewStats,
    'battery status': FeatureAction.viewBattery,
    'check battery': FeatureAction.viewBattery,
    'battery level': FeatureAction.viewBattery,
    'connection status': FeatureAction.viewConnection,
    'network status': FeatureAction.viewConnection,
    'check connection': FeatureAction.viewConnection,
    'show alerts': FeatureAction.viewAlerts,
    'alerts': FeatureAction.viewAlerts,
    'notifications': FeatureAction.viewAlerts,

    // Favorites commands
    'add favorite': FeatureAction.addFavorite,
    'save favorite': FeatureAction.addFavorite,
    'add to favorites': FeatureAction.addFavorite,
    'list favorites': FeatureAction.listFavorites,
    'show favorites': FeatureAction.listFavorites,
    'my favorites': FeatureAction.listFavorites,
    'open favorites': FeatureAction.listFavorites,
    'go to favorites': FeatureAction.goFavorites,
    'favorites': FeatureAction.goFavorites,
    'remove favorite': FeatureAction.removeFavorite,
    'delete favorite': FeatureAction.removeFavorite,

    // Emergency commands
    'emergency': FeatureAction.callEmergencyContact,
    'call emergency': FeatureAction.callEmergencyContact,
    'call emergency contact': FeatureAction.callEmergencyContact,
    'help me': FeatureAction.callEmergencyContact,
    'i need help': FeatureAction.callEmergencyContact,
    'sos': FeatureAction.callEmergencyContact,
    'show emergency contacts': FeatureAction.viewEmergencyContacts,
    'emergency contacts': FeatureAction.viewEmergencyContacts,
    'view emergency contacts': FeatureAction.viewEmergencyContacts,
    'open emergency contacts': FeatureAction.viewEmergencyContacts,
    'go to emergency contacts': FeatureAction.goEmergency,
    'add emergency contact': FeatureAction.addEmergencyContact,
    'new emergency contact': FeatureAction.addEmergencyContact,
    'send alert': FeatureAction.sendAlert,
    'alert': FeatureAction.sendAlert,
    'send sos': FeatureAction.sendAlert,

    // Connected users commands
    'show connected users': FeatureAction.viewConnectedUsers,
    'connected users': FeatureAction.viewConnectedUsers,
    'view connected users': FeatureAction.viewConnectedUsers,
    'my connections': FeatureAction.viewConnectedUsers,
    'go to connected users': FeatureAction.goConnectedUsers,
    'open connected users': FeatureAction.goConnectedUsers,
    'add connected user': FeatureAction.addConnectedUser,

    // Navigation commands
    'go home': FeatureAction.goHome,
    'home': FeatureAction.goHome,
    'home screen': FeatureAction.goHome,
    'main screen': FeatureAction.goHome,
    'dashboard': FeatureAction.goDashboard,
    'go dashboard': FeatureAction.goDashboard,
    'go to dashboard': FeatureAction.goDashboard,
    'open dashboard': FeatureAction.goDashboard,
    'vision': FeatureAction.goVision,
    'ai vision': FeatureAction.goVision,
    'camera': FeatureAction.goVision,
    'open camera': FeatureAction.goVision,
    'open vision': FeatureAction.goVision,
    'relatives': FeatureAction.goRelatives,
    'family': FeatureAction.goRelatives,
    'open relatives': FeatureAction.goRelatives,
    'go to relatives': FeatureAction.goRelatives,
    'settings': FeatureAction.goSettings,
    'open settings': FeatureAction.goSettings,
    'go to settings': FeatureAction.goSettings,
    'activity': FeatureAction.goActivity,
    'history': FeatureAction.goActivity,
    'open activity': FeatureAction.goActivity,
    'profile': FeatureAction.goProfile,
    'my profile': FeatureAction.goProfile,
    'open profile': FeatureAction.goProfile,
    'help': FeatureAction.goHelp,
    'show help': FeatureAction.goHelp,
    'open help': FeatureAction.goHelp,
    'help screen': FeatureAction.goHelp,
    'go back': FeatureAction.goBack,
    'back': FeatureAction.goBack,
    'previous screen': FeatureAction.goBack,

    // General commands
    'about': FeatureAction.about,
    'about app': FeatureAction.about,
    'logout': FeatureAction.logout,
    'sign out': FeatureAction.logout,
    'log out': FeatureAction.logout,
    'cancel': FeatureAction.cancel,
    'never mind': FeatureAction.cancel,
    'stop': FeatureAction.stop,
    'stop speaking': FeatureAction.stop,
    'be quiet': FeatureAction.stop,
    'repeat': FeatureAction.repeat,
    'say again': FeatureAction.repeat,
    'what did you say': FeatureAction.repeat,
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

      // Settings - Speech Speed
      case FeatureAction.speechFaster:
        await _executeSpeechFaster();
      case FeatureAction.speechSlower:
        await _executeSpeechSlower();
      case FeatureAction.speechNormal:
        await _executeSpeechNormal();
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
      case FeatureAction.toggleTheme:
        await _executeToggleTheme();
      case FeatureAction.darkMode:
        await _executeDarkMode();
      case FeatureAction.lightMode:
        await _executeLightMode();

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
      case FeatureAction.viewEmergencyContacts:
        await _executeViewEmergencyContacts();
      case FeatureAction.addEmergencyContact:
        await _executeAddEmergencyContact();
      case FeatureAction.sendAlert:
        await _executeSendAlert();

      // Connected Users
      case FeatureAction.viewConnectedUsers:
        await _executeViewConnectedUsers();
      case FeatureAction.addConnectedUser:
        await _executeAddConnectedUser();

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
      case FeatureAction.goHelp:
        _onNavigate?.call('/help');
        await _audioFeedback.speak('Opening help');
      case FeatureAction.goEmergency:
        _onNavigate?.call('/emergency');
        await _audioFeedback.speak('Opening emergency contacts');
      case FeatureAction.goFavorites:
        _onNavigate?.call('/favorites');
        await _audioFeedback.speak('Opening favorites');
      case FeatureAction.goConnectedUsers:
        _onNavigate?.call('/connected-users');
        await _audioFeedback.speak('Opening connected users');
      case FeatureAction.goBack:
        await _executeGoBack();

      // General
      case FeatureAction.help:
        await _executeShowHelp();
      case FeatureAction.about:
        await _executeShowAbout();
      case FeatureAction.logout:
        await _executeLogout();
      case FeatureAction.cancel:
        await _executeCancel();
      case FeatureAction.stop:
        await _executeStop();
      case FeatureAction.repeat:
        await _executeRepeat();
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

  // Speech speed implementations
  Future<void> _executeSpeechFaster() async {
    _onFeatureAction?.call(FeatureAction.speechFaster, {'direction': 'faster'});
    await _audioFeedback.speak('Speaking faster now');
  }

  Future<void> _executeSpeechSlower() async {
    _onFeatureAction?.call(FeatureAction.speechSlower, {'direction': 'slower'});
    await _audioFeedback.speak('Speaking slower now');
  }

  Future<void> _executeSpeechNormal() async {
    _onFeatureAction?.call(FeatureAction.speechNormal, {'direction': 'normal'});
    await _audioFeedback.speak('Speech speed reset to normal');
  }

  // Theme implementations
  Future<void> _executeToggleTheme() async {
    _onFeatureAction?.call(FeatureAction.toggleTheme, {});
    await _audioFeedback.speak('Theme toggled');
  }

  Future<void> _executeDarkMode() async {
    _onFeatureAction?.call(FeatureAction.darkMode, {'theme': 'dark'});
    await _audioFeedback.speak('Dark mode enabled');
  }

  Future<void> _executeLightMode() async {
    _onFeatureAction?.call(FeatureAction.lightMode, {'theme': 'light'});
    await _audioFeedback.speak('Light mode enabled');
  }

  // Emergency implementations
  Future<void> _executeViewEmergencyContacts() async {
    _onNavigate?.call('/emergency');
    await _audioFeedback.speak('Showing your emergency contacts');
  }

  Future<void> _executeAddEmergencyContact() async {
    _onNavigate?.call('/emergency');
    await _audioFeedback.speak('Opening form to add emergency contact');
    _onFeatureAction?.call(FeatureAction.addEmergencyContact, {});
  }

  // Connected users implementations
  Future<void> _executeViewConnectedUsers() async {
    _onNavigate?.call('/connected-users');
    await _audioFeedback.speak('Showing your connected users');
  }

  Future<void> _executeAddConnectedUser() async {
    _onNavigate?.call('/connected-users');
    await _audioFeedback.speak('Opening form to add connected user');
    _onFeatureAction?.call(FeatureAction.addConnectedUser, {});
  }

  // General command implementations
  Future<void> _executeGoBack() async {
    _onFeatureAction?.call(FeatureAction.goBack, {});
    await _audioFeedback.speak('Going back');
  }

  Future<void> _executeCancel() async {
    _onFeatureAction?.call(FeatureAction.cancel, {});
    await _audioFeedback.speak('Cancelled');
  }

  Future<void> _executeStop() async {
    await _audioFeedback.stopSpeaking();
    _onFeatureAction?.call(FeatureAction.stop, {});
  }

  // Note: Repeat functionality would need to track last spoken text
  // from AudioFeedbackEngine which manages the speech queue
  Future<void> _executeRepeat() async {
    // For now, provide helpful guidance
    await _audioFeedback.speak('To repeat last message, please ask me again');
  }
}
