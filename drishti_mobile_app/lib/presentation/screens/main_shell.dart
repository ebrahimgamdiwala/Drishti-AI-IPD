/// Drishti App - Main Shell
///
/// Bottom navigation container for main screens.
library;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/voice_navigation_provider.dart';
import 'home/home_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'relatives/relatives_screen.dart';
import 'activity/activity_screen.dart';
import 'settings/settings_screen.dart';
import 'vlm/vlm_chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();

  /// Get the current instance for voice navigation
  // ignore: library_private_types_in_public_api
  static _MainShellState? get currentInstance => _MainShellState._instance;
}

class _MainShellState extends State<MainShell> {
  // Static reference to the current instance for voice navigation
  static _MainShellState? _instance;

  int _currentIndex = 0;
  bool _hotwordListening = false;
  Timer? _restartTimer;

  final List<Widget> _screens = const [
    HomeScreen(),
    DashboardScreen(),
    VLMChatScreen(),
    RelativesScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  List<_NavItem> _getNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: l10n.dashboard,
      ),
      _NavItem(
        icon: Icons.psychology_outlined,
        activeIcon: Icons.psychology,
        label: 'AI Vision',
      ),
      _NavItem(
        icon: Icons.people_outlined,
        activeIcon: Icons.people,
        label: l10n.relatives,
      ),
      _NavItem(
        icon: Icons.history_outlined,
        activeIcon: Icons.history,
        label: l10n.activity,
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    // Set static instance reference
    _instance = this;

    // Initialize voice navigation system
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceNav = context.read<VoiceNavigationProvider>();
      if (!voiceNav.isInitialized) {
        voiceNav.initialize();
      }

      // Announce initial screen (Home)
      _announceCurrentScreen();

      // Start global hotword listening
      _startGlobalHotwordListening();
    });
  }

  @override
  void dispose() {
    // Stop global hotword listening
    final voiceNav = context.read<VoiceNavigationProvider>();
    voiceNav.stopHotwordListening();

    // Cancel restart timer
    _restartTimer?.cancel();

    // Clear static instance reference
    if (_instance == this) {
      _instance = null;
    }
    super.dispose();
  }

  /// Handle hotword detection
  Future<void> _onHotwordDetected() async {
    final voiceNav = context.read<VoiceNavigationProvider>();

    debugPrint('[MainShell] 🎤 Hotword detected! Starting voice command...');

    // Provide brief audio feedback for hotword detection
    // Use speakImmediate to ensure it plays quickly without queuing
    await voiceNav.audioFeedback.speakImmediate('Listening');

    // Cancel any pending restart - VoiceService handles restarts now
    _restartTimer?.cancel();

    // Wait for STT to fully stop and for audio feedback to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Start voice command - VoiceService will resume continuous listening after
    await voiceNav.onMicrophoneTap();

    // Note: VoiceService.resumeHotwordListening() is called automatically
    // after command processing in VoiceNavigationController.processVoiceCommand()
  }

  /// Start global hotword listening that works across all screens
  Future<void> _startGlobalHotwordListening() async {
    final voiceNav = context.read<VoiceNavigationProvider>();

    debugPrint('[MainShell] Checking STT availability for global hotword...');

    // Wait a bit for STT to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    // Only start hotword if STT is available
    if (voiceNav.isSpeechRecognitionAvailable) {
      debugPrint(
        '[MainShell] ✅ STT available, starting global hotword listening',
      );

      // Start listening for "Hey Vision" hotword globally
      await voiceNav.startHotwordListening(
        onHotwordDetected: _onHotwordDetected,
      );

      setState(() => _hotwordListening = true);
      debugPrint('[MainShell] ✅ Global hotword listening started');
    } else {
      debugPrint('[MainShell] ❌ STT not available, global hotword won\'t work');
      setState(() => _hotwordListening = false);
    }
  }

  /// Navigate to a screen by route name (for voice navigation)
  void navigateToRoute(String route) {
    int? targetIndex;

    switch (route) {
      case '/home':
        targetIndex = 0;
        break;
      case '/dashboard':
        targetIndex = 1;
        break;
      case '/vision':
        targetIndex = 2;
        break;
      case '/relatives':
        targetIndex = 3;
        break;
      case '/activity':
        targetIndex = 4;
        break;
      case '/settings':
        targetIndex = 5;
        break;
    }

    if (targetIndex != null && targetIndex != _currentIndex) {
      // Clear any pending audio feedback from previous screen
      final voiceNav = context.read<VoiceNavigationProvider>();
      voiceNav.audioFeedback.clearQueue();
      voiceNav.audioFeedback.stopSpeaking();
      
      setState(() {
        _currentIndex = targetIndex!;
      });

      // Announce new screen after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _announceCurrentScreen();
        }
      });
    }
  }

  void _announceCurrentScreen() {
    final voiceNav = context.read<VoiceNavigationProvider>();

    // Map of screen names and actions
    final screenInfo = {
      0: {
        'name': 'Home',
        'actions': ['Tap microphone to speak', 'Quick scan', 'View tips'],
      },
      1: {
        'name': 'Dashboard',
        'actions': ['View stats', 'Check battery', 'View alerts', 'Refresh'],
      },
      2: {
        'name': 'AI Vision',
        'actions': ['Chat with AI', 'Analyze images', 'Ask questions'],
      },
      3: {
        'name': 'Relatives',
        'actions': ['View relatives', 'Add new relative', 'Sort list'],
      },
      4: {
        'name': 'Activity',
        'actions': ['View history', 'Filter activities', 'Check recent alerts'],
      },
      5: {
        'name': 'Settings',
        'actions': [
          'Change theme',
          'Adjust voice speed',
          'Manage emergency contacts',
          'View profile',
        ],
      },
    };

    final info = screenInfo[_currentIndex];
    if (info != null) {
      voiceNav.audioFeedback.announceScreen(
        info['name'] as String,
        info['actions'] as List<String>,
      );

      // Update current screen route
      final routes = [
        '/home',
        '/dashboard',
        '/vision',
        '/relatives',
        '/activity',
        '/settings',
      ];
      voiceNav.updateCurrentScreen(routes[_currentIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkBackgroundGradientStart,
                  AppColors.darkBackgroundGradientEnd,
                ]
              : [
                  AppColors.lightBackgroundGradientStart,
                  AppColors.lightBackgroundGradientEnd,
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Main content with IndexedStack
            IndexedStack(index: _currentIndex, children: _screens),

            // Global hotword indicator (only show on home screen)
            if (_hotwordListening && _currentIndex == 0)
              Positioned(
                top:
                    MediaQuery.of(context).padding.top +
                    90, // More padding below header
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: AppColors.primaryBlue, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Say "Hey Vision"',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassDarkSurface
                    : AppColors.glassWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.glassDarkBorder
                        : AppColors.glassBorder,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                minimum: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          _getNavItems(context).length,
                          (index) => _buildNavItem(index, isDark, context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark, BuildContext context) {
    final isSelected = _currentIndex == index;
    final item = _getNavItems(context)[index];

    return Semantics(
      label: item.label,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          // Clear any pending audio feedback from previous screen
          final voiceNav = context.read<VoiceNavigationProvider>();
          voiceNav.audioFeedback.clearQueue();
          voiceNav.audioFeedback.stopSpeaking();
          
          setState(() {
            _currentIndex = index;
          });
          // Announce new screen after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            _announceCurrentScreen();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                size: 26,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
