/// Drishti App - Privacy Policy Screen
///
/// Display privacy policy content.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/user_repository.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final UserRepository _repository = UserRepository();
  Map<String, dynamic> _policyContent = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final content = await _repository.getPrivacyPolicy();
      setState(() {
        _policyContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load privacy policy: $e')),
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
        title: const Text('Privacy Policy'),
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
                      _policyContent['title'] ?? 'Privacy Policy',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 8),

                    if (_policyContent['lastUpdated'] != null)
                      Text(
                        'Last updated: ${_policyContent['lastUpdated']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Sections
                    if (_policyContent['sections'] != null)
                      ...(_policyContent['sections'] as List)
                          .asMap()
                          .entries
                          .map((entry) {
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

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    section['content'] ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 100 * index),
                              duration: 300.ms,
                            );
                          }),
                  ],
                ),
              ),
            ),
    );
  }
}
