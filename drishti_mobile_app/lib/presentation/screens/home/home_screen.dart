/// Drishti App - Home Screen
///
/// Voice scan interface with microphone button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/voice_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = AppStrings.tapToSpeak;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initVoice();
  }

  Future<void> _initVoice() async {
    await _voiceService.initTts();
    await _voiceService.initStt();

    // Announce screen on first load
    Future.delayed(const Duration(milliseconds: 500), () {
      _voiceService.speak(
        'Home screen. Tap the large button to speak a command or scan your surroundings.',
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleMicTap() async {
    if (_isProcessing) return;

    if (_isListening) {
      // Stop listening
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
        _statusText = AppStrings.tapToSpeak;
      });
      _pulseController.stop();
      _pulseController.reset();
    } else {
      // Start listening
      setState(() {
        _isListening = true;
        _statusText = AppStrings.listening;
      });
      _pulseController.repeat();

      await _voiceService.startListening(
        onResult: (text) async {
          setState(() {
            _isListening = false;
            _isProcessing = true;
            _statusText = AppStrings.processing;
          });
          _pulseController.stop();

          // Process the voice command
          // Process the voice command
          await _processCommand(text);
        },
      );
    }
  }

  Future<void> _processCommand(String command) async {
    // TODO: Implement command processing logic
    debugPrint('Processing command: $command');

    await Future.delayed(const Duration(seconds: 1)); // Simulate processing

    setState(() {
      _isProcessing = false;
      _statusText = AppStrings.tapToSpeak;
    });

    await _voiceService.speak('I heard: $command');
  }

  void _handleQuickScan() {
    // TODO: Implement quick scan
    debugPrint('Quick scan tapped');
    _voiceService.speak('Starting quick scan');
  }

  Widget _buildPulseRing(int index, double value) {
    final double size = 120 + (index * 30.0);
    final double opacity = (1.0 - value) * 0.5;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(
          parent: _pulseController,
          curve: Interval(index * 0.2, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
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
                          'Hi, ${AppStrings.welcomeBack}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          user?.name ?? 'User',
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
                        const Text(
                          'Online',
                          style: TextStyle(
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

            // Microphone button
            GestureDetector(
                  onTap: _handleMicTap,
                  child: Semantics(
                    label: AppStrings.microphoneButton,
                    button: true,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soundwave animation (multiple rings)
                            if (_isListening) ...[
                              for (int i = 0; i < 3; i++)
                                _buildPulseRing(i, _pulseController.value),
                            ],

                            // Main button
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
              _statusText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isListening ? AppColors.primaryBlue : null,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Quick scan button
            Semantics(
              label: AppStrings.scanButton,
              button: true,
              child: TextButton.icon(
                onPressed: _handleQuickScan,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(AppStrings.quickScan),
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

            // Quick tips
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tips',
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
                              text: 'Say: "Show obstacles"',
                              icon: Icons.remove_red_eye,
                            ),
                            _TipCard(
                              text: 'Say: "Who is near?"',
                              icon: Icons.people,
                            ),
                            _TipCard(
                              text: 'Say: "Read text"',
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
