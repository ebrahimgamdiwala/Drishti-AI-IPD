/// Drishti App - About Screen
///
/// Display about app information.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/user_repository.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final UserRepository _repository = UserRepository();
  Map<String, dynamic> _aboutContent = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final content = await _repository.getAboutContent();
      setState(() {
        _aboutContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load about content: $e')),
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
        title: const Text('About'),
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
                    // App Icon/Logo
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().scale(duration: 500.ms),

                    const SizedBox(height: 24),

                    // Title
                    Center(
                      child: Text(
                        _aboutContent['title'] ?? 'Drishti AI',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 8),

                    // Version
                    if (_aboutContent['version'] != null)
                      Center(
                        child: Text(
                          'Version ${_aboutContent['version']}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Description
                    if (_aboutContent['description'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _aboutContent['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Features
                    if (_aboutContent['features'] != null) ...[
                      Text(
                        'Features',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...(_aboutContent['features'] as List)
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final feature = entry.value as String;

                            return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: 250 + (index * 50),
                                  ),
                                  duration: 300.ms,
                                )
                                .slideX(begin: -0.1, end: 0);
                          }),

                      const SizedBox(height: 24),
                    ],

                    // Contact
                    if (_aboutContent['contact'] != null) ...[
                      Text(
                        'Contact Us',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_aboutContent['contact']['email'] != null)
                              _buildContactRow(
                                Icons.email_outlined,
                                _aboutContent['contact']['email'],
                              ),
                            if (_aboutContent['contact']['website'] !=
                                null) ...[
                              const SizedBox(height: 8),
                              _buildContactRow(
                                Icons.language,
                                _aboutContent['contact']['website'],
                              ),
                            ],
                            if (_aboutContent['contact']['support'] !=
                                null) ...[
                              const SizedBox(height: 8),
                              _buildContactRow(
                                Icons.support_agent,
                                _aboutContent['contact']['support'],
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                      const SizedBox(height: 24),
                    ],

                    // Legal
                    if (_aboutContent['legal'] != null)
                      Center(
                        child: Column(
                          children: [
                            if (_aboutContent['legal']['copyright'] != null)
                              Text(
                                _aboutContent['legal']['copyright'],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            if (_aboutContent['team'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _aboutContent['team'],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
