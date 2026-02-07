/// Drishti App - Home Screen
///
/// Voice scan interface with microphone button.
library;

import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/voice_navigation_provider.dart';
import '../../../data/models/voice_navigation/microphone_state.dart';
import '../../widgets/voice_navigation/voice_navigation_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Handle microphone button tap - delegates to VoiceNavigationProvider
  Future<void> _handleMicTap(VoiceNavigationProvider voiceNav) async {
    await voiceNav.onMicrophoneTap();
  }

  /// Handle quick scan - uses voice navigation for vision intent
  Future<void> _handleQuickScan(VoiceNavigationProvider voiceNav) async {
    // Trigger a vision scan via voice command
    await voiceNav.processVoiceCommand('scan surroundings');
  }

  /// Get status text based on microphone state
  String _getStatusText(MicrophoneState state, AppLocalizations l10n) {
    switch (state) {
      case MicrophoneState.idle:
        return l10n.tapToSpeak;
      case MicrophoneState.listening:
        return l10n.listening;
      case MicrophoneState.processing:
        return l10n.processing;
      case MicrophoneState.speaking:
        return l10n.speaking;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final voiceNav = context.watch<VoiceNavigationProvider>();
    final micState = voiceNav.microphoneState;
    
    // Control pulse animation based on microphone state
    if (micState == MicrophoneState.listening && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (micState != MicrophoneState.listening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryBlue,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.welcomeBack,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          user?.name ?? l10n.user,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Connection status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.online,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
            ),

            const Spacer(),

            // Microphone button with voice navigation integration
            MicrophoneButton(
              state: micState,
              onTap: () => _handleMicTap(voiceNav),
              size: 120,
              showLabel: false,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 24),

            // Status text
            Text(
              _getStatusText(micState, l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: micState == MicrophoneState.listening 
                    ? AppColors.primaryBlue 
                    : null,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Quick scan button
            Semantics(
              label: l10n.scanButton,
              button: true,
              child: TextButton.icon(
                onPressed: () => _handleQuickScan(voiceNav),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.quickScan),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

            const Spacer(),

            // Test buttons for STT workaround
            if (!voiceNav.isSpeechRecognitionAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.testVoiceCommands,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.speechRecognitionUnavailable,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TestCommandButton(
                          label: l10n.scan,
                          command: 'scan surroundings',
                          icon: Icons.camera_alt,
                          onPressed: () => voiceNav.processVoiceCommand('scan surroundings'),
                        ),
                        _TestCommandButton(
                          label: l10n.dashboard,
                          command: 'go to dashboard',
                          icon: Icons.dashboard,
                          onPressed: () => voiceNav.processVoiceCommand('go to dashboard'),
                        ),
                        _TestCommandButton(
                          label: l10n.settings,
                          command: 'go to settings',
                          icon: Icons.settings,
                          onPressed: () => voiceNav.processVoiceCommand('go to settings'),
                        ),
                        _TestCommandButton(
                          label: l10n.relatives,
                          command: 'show relatives',
                          icon: Icons.people,
                          onPressed: () => voiceNav.processVoiceCommand('show relatives'),
                        ),
                        _TestCommandButton(
                          label: l10n.activity,
                          command: 'show activity',
                          icon: Icons.history,
                          onPressed: () => voiceNav.processVoiceCommand('show activity'),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

            // Quick tips
            if (voiceNav.isSpeechRecognitionAvailable)
              Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.quickTips,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _TipCard(
                                text: l10n.sayShowObstacles,
                                icon: Icons.remove_red_eye,
                              ),
                              _TipCard(
                                text: l10n.sayWhoIsNear,
                                icon: Icons.people,
                              ),
                              _TipCard(
                                text: l10n.sayReadText,
                                icon: Icons.text_fields,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 20),
          ],
        );
          },
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const _TipCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TestCommandButton extends StatelessWidget {
  final String label;
  final String command;
  final IconData icon;
  final VoidCallback onPressed;

  const _TestCommandButton({
    required this.label,
    required this.command,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Test command: $command',
      button: true,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark 
              ? AppColors.darkCard 
              : AppColors.lightCard,
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
