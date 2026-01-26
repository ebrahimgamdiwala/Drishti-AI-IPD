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
}
