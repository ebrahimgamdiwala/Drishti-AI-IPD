/// Drishti App - Help Screen
///
/// Display help and FAQ content.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/user_repository.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final UserRepository _repository = UserRepository();
  Map<String, dynamic> _helpContent = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final content = await _repository.getHelpContent();
      setState(() {
        _helpContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load help content: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _helpContent['title'] ?? 'Help & FAQ',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Voice Controls Section (Added)
                    _buildVoiceControlsSection(isDark),

                    const SizedBox(height: 24),

                    // Sections
                    if (_helpContent['sections'] != null)
                      ...(_helpContent['sections'] as List).asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final section = entry.value as Map<String, dynamic>;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section['title'] ?? '',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),

                              if (section['items'] != null)
                                ...(section['items'] as List).map((item) {
                                  final itemMap = item as Map<String, dynamic>;
                                  return _buildFAQItem(
                                    itemMap['question'] ?? '',
                                    itemMap['answer'] ?? '',
                                    isDark,
                                  );
                                }),

                              const SizedBox(height: 24),
                            ],
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                            duration: 300.ms,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFAQItem(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceControlsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Controls Guide',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Getting Started',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Say "Hey Vision" to activate voice mode\n2. Wait for the beep and speak your command\n3. The app will confirm your action with voice feedback',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Vision & Scanning
              _buildVoiceCommandGroup('Vision & Scanning', [
                '"Scan surroundings" - Analyze your current environment',
                '"Read text" - Extract and read visible text',
                '"Detect obstacles" - Identify obstacles in your path',
                '"Identify people" - Recognize nearby people',
                '"Analyze scene" - Get detailed scene analysis',
                '"What\'s ahead" - Get description of what\'s in front',
              ], isDark),
              const SizedBox(height: 12),

              // Relatives Management
              _buildVoiceCommandGroup('Relatives & People', [
                '"Add relative" - Start adding a new family member',
                '"List relatives" - Hear all your known relatives',
                '"Find [name]" - Locate a specific relative',
                '"Edit relative" - Modify relative information',
                '"Remove relative" - Delete a relative entry',
                '"Who is near me" - Identify nearby known people',
              ], isDark),
              const SizedBox(height: 12),

              // Settings & Preferences
              _buildVoiceCommandGroup('Settings & Preferences', [
                '"Speak faster" / "Speak slower" - Change speech speed',
                '"Normal speed" - Reset speech to default',
                '"Dark mode" / "Light mode" - Change app theme',
                '"Toggle theme" - Switch between light and dark',
                '"Increase volume" / "Decrease volume" - Adjust speaker volume',
                '"Toggle vibration" - Toggle haptic feedback',
                '"Change language" - Switch app language',
              ], isDark),
              const SizedBox(height: 12),

              // Emergency, Favorites & Connected Users
              _buildVoiceCommandGroup('Emergency & Contacts', [
                '"Emergency" / "SOS" - Activate emergency mode',
                '"Call emergency contact" - Initiate emergency call',
                '"Show emergency contacts" - View your emergency contacts',
                '"Add emergency contact" - Add new emergency contact',
                '"Send alert" - Send SOS to contacts',
                '"Show favorites" - View your favorites',
                '"Add to favorites" - Add current item to favorites',
                '"Connected users" - View your connected users',
              ], isDark),
              const SizedBox(height: 12),

              // Navigation
              _buildVoiceCommandGroup('Navigation', [
                '"Go home" - Navigate to home screen',
                '"Go to settings" - Open settings page',
                '"Go to dashboard" - View dashboard',
                '"Go to profile" - Access your profile',
                '"Go to relatives" - Open relatives list',
                '"Go to favorites" - Open favorites screen',
                '"Go to emergency contacts" - Open emergency contacts',
                '"Go to connected users" - View connected users',
                '"Go back" / "Back" - Return to previous screen',
                '"Help" - Get voice control assistance',
                '"Stop" / "Cancel" - Stop current action',
              ], isDark),
              const SizedBox(height: 12),

              // Activity & History
              _buildVoiceCommandGroup('Activity & History', [
                '"View activity" - Check activity history',
                '"Clear activity" - Remove activity log',
                '"Show recent" - Display recent actions',
                '"Filter by date" - Search activity by date range',
              ], isDark),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro Tips',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Speak clearly and naturally - no need for special phrasing\n'
                      '• Commands are case-insensitive\n'
                      '• Wait for the beep before speaking\n'
                      '• You can chain commands without repeating the hotword\n'
                      '• Say "repeat" to hear the last instruction again\n'
                      '• The app remembers context between commands',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildVoiceCommandGroup(
    String title,
    List<String> commands,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 6),
        ...commands.map(
          (command) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    command,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
