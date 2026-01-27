/// Voice Router
///
/// Translates navigation intents into screen transitions.
library;

import 'package:flutter/material.dart';
import '../../models/voice_navigation/voice_navigation_models.dart';
import '../../../routes/app_routes.dart';
import '../../../presentation/screens/main_shell.dart';
import 'audio_feedback_engine.dart';

/// Route name constants for voice navigation
///
/// These constants map to the routes defined in [AppRoutes].
class VoiceRoutes {
  VoiceRoutes._();

  /// Home screen route
  static const String home = AppRoutes.home;

  /// Dashboard screen route
  static const String dashboard = AppRoutes.dashboard;

  /// Settings screen route
  static const String settings = AppRoutes.settings;

  /// Profile screen route
  static const String profile = AppRoutes.profile;

  /// Relatives screen route
  static const String relatives = AppRoutes.relatives;

  /// Activity screen route
  static const String activity = AppRoutes.activity;

  /// Vision/VLM screen route (if exists)
  static const String vision = '/vision';

  /// Authentication screen route
  static const String auth = AppRoutes.login;

  /// Map of screen names to routes for voice commands
  static const Map<String, String> screenNameToRoute = {
    'home': home,
    'dashboard': dashboard,
    'settings': settings,
    'setting': settings,
    'profile': profile,
    'relatives': relatives,
    'family': relatives,
    'activity': activity,
    'history': activity,
    'vision': vision,
    'camera': vision,
    'auth': auth,
    'login': auth,
    'sign in': auth,
  };

  /// Map of routes to friendly screen names for announcements
  static const Map<String, String> routeToScreenName = {
    home: 'Home',
    dashboard: 'Dashboard',
    settings: 'Settings',
    profile: 'Profile',
    relatives: 'Relatives',
    activity: 'Activity',
    vision: 'Vision',
    auth: 'Authentication',
  };
}

/// Voice Router for navigation based on voice commands
///
/// This router translates voice navigation intents into screen transitions
/// and provides audio feedback for navigation actions.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9
class VoiceRouter {
  final GlobalKey<NavigatorState>? _navigatorKey;
  final AudioFeedbackEngine _audioFeedback;

  VoiceRouter({
    GlobalKey<NavigatorState>? navigatorKey,
    required AudioFeedbackEngine audioFeedback,
  }) : _navigatorKey = navigatorKey,
       _audioFeedback = audioFeedback;

  /// Route to screen based on classified intent
  ///
  /// Analyzes the intent and performs the appropriate navigation action.
  /// Provides audio feedback for the navigation.
  ///
  /// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7
  Future<void> routeFromIntent(ClassifiedIntent intent) async {
    if (intent.type != IntentType.navigation) {
      return;
    }

    final parameters = intent.parameters;

    // Handle special navigation actions
    if (parameters.containsKey('action')) {
      final action = parameters['action'] as String;

      if (action == 'back') {
        await goBack();
        return;
      } else if (action == 'home') {
        await goHome();
        return;
      }
    }

    // Handle screen navigation
    if (parameters.containsKey('route')) {
      final route = parameters['route'] as String;
      await navigateTo(route);
      return;
    }

    // Handle screen name navigation
    if (parameters.containsKey('screen')) {
      final screenName = parameters['screen'] as String;
      final route = VoiceRoutes.screenNameToRoute[screenName];

      if (route != null) {
        await navigateTo(route);
        return;
      }
    }

    // If we couldn't determine the navigation target
    await _audioFeedback.reportError(
      'I couldn\'t find that screen. Please try again.',
    );
  }

  /// Navigate to a specific screen by route name
  ///
  /// Performs the navigation and announces the destination.
  ///
  /// Requirements: 7.1, 7.4, 7.5, 7.6, 7.7, 7.8
  Future<void> navigateTo(String routeName) async {
    try {
      // Get the friendly screen name for announcement
      final screenName =
          VoiceRoutes.routeToScreenName[routeName] ??
          _extractScreenNameFromRoute(routeName);

      // Announce navigation
      await _audioFeedback.announceNavigation(screenName);

      // Check if we're navigating within the main shell
      final mainShellRoutes = [
        VoiceRoutes.home,
        VoiceRoutes.dashboard,
        VoiceRoutes.settings,
        VoiceRoutes.relatives,
        VoiceRoutes.activity,
        VoiceRoutes.vision,
      ];

      if (mainShellRoutes.contains(routeName)) {
        // Use MainShell's navigation method for bottom nav screens
        final shellState = MainShell.currentInstance;
        if (shellState != null) {
          shellState.navigateToRoute(routeName);
          return;
        }
      }

      // Fallback to regular navigation for other routes
      final context = _getNavigatorContext();
      if (context == null) {
        await _audioFeedback.reportError(
          'Navigation not available. Please try again.',
        );
        return;
      }

      // ignore: use_build_context_synchronously
      await Navigator.of(context).pushNamed(routeName);
    } catch (e) {
      await _audioFeedback.reportError(
        'Could not navigate to that screen. Please try again.',
      );
    }
  }

  /// Go back to the previous screen
  ///
  /// Pops the current route from the navigation stack.
  ///
  /// Requirements: 7.2
  Future<void> goBack() async {
    final context = _getNavigatorContext();

    if (context == null) {
      await _audioFeedback.reportError(
        'Navigation not available. Please try again.',
      );
      return;
    }

    try {
      // Check if we can go back
      // ignore: use_build_context_synchronously
      if (Navigator.of(context).canPop()) {
        await _audioFeedback.speak('Going back');
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        await _audioFeedback.speak('Already at the first screen');
      }
    } catch (e) {
      await _audioFeedback.reportError('Could not go back. Please try again.');
    }
  }

  /// Go to the home screen
  ///
  /// Navigates to the home screen, clearing the navigation stack if needed.
  ///
  /// Requirements: 7.3
  Future<void> goHome() async {
    final context = _getNavigatorContext();

    if (context == null) {
      await _audioFeedback.reportError(
        'Navigation not available. Please try again.',
      );
      return;
    }

    try {
      await _audioFeedback.announceNavigation('Home');

      // Navigate to home, replacing the current route
      await Navigator.of(
        context, // ignore: use_build_context_synchronously
      ).pushNamedAndRemoveUntil(VoiceRoutes.home, (route) => false);
    } catch (e) {
      await _audioFeedback.reportError(
        'Could not navigate to home. Please try again.',
      );
    }
  }

  /// Announce the current screen
  ///
  /// Speaks the name of the current screen and available actions.
  ///
  /// Requirements: 7.8, 14.3
  Future<void> announceCurrentScreen() async {
    final context = _getNavigatorContext();

    if (context == null) {
      return;
    }

    try {
      // Get current route name
      final currentRoute = ModalRoute.of(context)?.settings.name;

      if (currentRoute == null) {
        return;
      }

      // Get friendly screen name
      final screenName =
          VoiceRoutes.routeToScreenName[currentRoute] ??
          _extractScreenNameFromRoute(currentRoute);

      // Get available actions for this screen
      final actions = getAvailableActions(currentRoute);

      // Announce screen with actions
      await _audioFeedback.announceScreen(screenName, actions);
    } catch (e) {
      // Silently fail - don't interrupt user with error for announcement
    }
  }

  /// Get available voice actions for the current screen
  ///
  /// Returns a list of voice commands that are available on the given screen.
  ///
  /// Requirements: 7.9, 14.3
  List<String> getAvailableActions([String? routeName]) {
    final route = routeName ?? _getCurrentRoute();

    if (route == null) {
      return _getCommonActions();
    }

    // Screen-specific actions
    switch (route) {
      case VoiceRoutes.home:
        return [
          ..._getCommonActions(),
          'scan surroundings',
          'check for obstacles',
          'who is near me',
        ];

      case VoiceRoutes.dashboard:
        return [..._getCommonActions(), 'view activity', 'check alerts'];

      case VoiceRoutes.settings:
        return [
          ..._getCommonActions(),
          'increase volume',
          'decrease volume',
          'change language',
          'set emergency contact',
        ];

      case VoiceRoutes.profile:
        return [..._getCommonActions(), 'edit profile', 'view settings'];

      case VoiceRoutes.relatives:
        return [
          ..._getCommonActions(),
          'add relative',
          'view relative details',
        ];

      case VoiceRoutes.activity:
        return [
          ..._getCommonActions(),
          'view recent activity',
          'filter by date',
        ];

      case VoiceRoutes.vision:
        return [
          ..._getCommonActions(),
          'scan surroundings',
          'read text',
          'identify objects',
        ];

      default:
        return _getCommonActions();
    }
  }

  /// Get common actions available on all screens
  ///
  /// These actions are available regardless of the current screen.
  List<String> _getCommonActions() {
    return ['go back', 'go home', 'open settings', 'help'];
  }

  /// Get the current route name
  String? _getCurrentRoute() {
    final context = _getNavigatorContext();
    if (context == null) return null;

    return ModalRoute.of(context)?.settings.name;
  }

  /// Get the navigator context
  ///
  /// Returns the current context from the navigator key if available.
  BuildContext? _getNavigatorContext() {
    return _navigatorKey?.currentContext;
  }

  /// Extract a friendly screen name from a route path
  ///
  /// Converts route paths like '/settings' to 'Settings'
  String _extractScreenNameFromRoute(String route) {
    // Remove leading slash and convert to title case
    final name = route.replaceFirst('/', '');

    if (name.isEmpty) {
      return 'Home';
    }

    // Convert kebab-case or snake_case to title case
    final words = name.split(RegExp(r'[-_]'));
    final titleCase = words
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');

    return titleCase;
  }
}
