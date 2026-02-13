/// Voice-Guided Relative Addition Screen
///
/// Full-screen hands-free relative addition with visual feedback.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/voice_service.dart';
import '../../../data/services/voice_navigation/voice_relative_flow.dart';
import '../../../data/repositories/relatives_repository.dart';
import '../../widgets/glass_card.dart';

class VoiceRelativeFlowScreen extends StatefulWidget {
  const VoiceRelativeFlowScreen({super.key});

  @override
  State<VoiceRelativeFlowScreen> createState() => _VoiceRelativeFlowScreenState();
}

class _VoiceRelativeFlowScreenState extends State<VoiceRelativeFlowScreen> {
  late VoiceRelativeFlow _flow;
  VoiceRelativeStep _currentStep = VoiceRelativeStep.welcome;
  bool _isListening = false;
  String _name = '';
  String _relationship = '';
  File? _photo;
  String? _notes;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  void _initializeFlow() {
    _flow = VoiceRelativeFlow(
      voiceService: VoiceService(),
      repository: RelativesRepository(),
      onStepChanged: (step) {
        if (mounted) {
          setState(() => _currentStep = step);
        }
      },
      onListeningChanged: (isListening) {
        if (mounted) {
          setState(() => _isListening = isListening);
        }
      },
      onDataChanged: (name, relationship, photo, notes) {
        if (mounted) {
          setState(() {
            _name = name;
            _relationship = relationship;
            _photo = photo;
            _notes = notes;
          });
        }
      },
    );

    // Start the flow automatically
    _startFlow();
  }

  Future<void> _startFlow() async {
    setState(() => _isProcessing = true);

    final result = await _flow.start();

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result.isSuccess) {
      // Return the created relative
      Navigator.pop(context, result.relative);
    } else if (result.cancelled) {
      // User cancelled
      Navigator.pop(context);
    } else if (result.error != null) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.error}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _flow.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with glassmorphism
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice-Guided',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Add New Relative',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _flow.cancel();
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondaryLight,
                      ),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
            ),

            // Step indicator with glassmorphism
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _getStepText(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStepIndicator(),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: -0.2, end: 0),
            ),

            const SizedBox(height: 20),

            // Listening indicator with glassmorphism
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                      AppColors.primaryBlue.withValues(alpha: 0.05),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            duration: 1500.ms,
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            duration: 1500.ms,
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1, 1),
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Listening...',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getListeningHint(),
                              style: TextStyle(
                                color: AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Animated pulse indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeOut(duration: 1000.ms)
                          .scale(
                            duration: 1000.ms,
                            begin: const Offset(1, 1),
                            end: const Offset(1.8, 1.8),
                          ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
              ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Photo preview with glassmorphism
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildPhotoPreview(),
                          const SizedBox(height: 16),
                          Text(
                            _photo != null ? 'Photo Captured' : 'No Photo Yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _photo != null
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 16),

                    // Data preview with glassmorphism
                    _buildDataPreview(),

                    const SizedBox(height: 16),

                    // Status message
                    if (_isProcessing)
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getStatusMessage(),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Cancel button with glassmorphism
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: EdgeInsets.zero,
                onTap: () {
                  _flow.cancel();
                  Navigator.pop(context);
                },
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      {'icon': Icons.person_outline, 'label': 'Name'},
      {'icon': Icons.family_restroom, 'label': 'Relation'},
      {'icon': Icons.camera_alt, 'label': 'Photo'},
      {'icon': Icons.notes, 'label': 'Notes'},
      {'icon': Icons.check_circle_outline, 'label': 'Confirm'},
    ];

    int currentIndex = _currentStep.index - 1;
    if (currentIndex < 0) currentIndex = 0;
    if (currentIndex >= steps.length) currentIndex = steps.length - 1;

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentIndex;
        final isCompleted = index < currentIndex;
        final step = steps[index];

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isCompleted || isActive
                      ? AppColors.primaryGradient
                      : null,
                  color: isCompleted || isActive
                      ? null
                      : AppColors.lightInputFill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : step['icon'] as IconData,
                  color: isCompleted || isActive
                      ? Colors.white
                      : AppColors.textSecondaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _photo != null
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.1),
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
        border: Border.all(
          color: _photo != null
              ? AppColors.primaryBlue
              : AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: _photo != null
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: _photo != null
            ? Image.file(_photo!, fit: BoxFit.cover)
            : Center(
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.primaryBlue.withValues(alpha: 0.4),
                  size: 56,
                ),
              ),
      ),
    );
  }

  Widget _buildDataPreview() {
    return Column(
      children: [
        if (_name.isNotEmpty) _buildDataField('Name', _name, Icons.person_outline),
        if (_name.isNotEmpty && _relationship.isNotEmpty) const SizedBox(height: 12),
        if (_relationship.isNotEmpty)
          _buildDataField('Relationship', _relationship, Icons.family_restroom),
        if (_notes != null && _notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDataField('Notes', _notes!, Icons.notes),
        ],
      ],
    );
  }

  Widget _buildDataField(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  String _getStepText() {
    switch (_currentStep) {
      case VoiceRelativeStep.welcome:
        return 'Getting Started';
      case VoiceRelativeStep.name:
        return 'Step 1 of 5';
      case VoiceRelativeStep.relationship:
        return 'Step 2 of 5';
      case VoiceRelativeStep.photo:
        return 'Step 3 of 5';
      case VoiceRelativeStep.notes:
        return 'Step 4 of 5';
      case VoiceRelativeStep.confirm:
        return 'Step 5 of 5';
      case VoiceRelativeStep.saving:
        return 'Saving...';
      case VoiceRelativeStep.complete:
        return 'Complete!';
    }
  }

  String _getListeningHint() {
    switch (_currentStep) {
      case VoiceRelativeStep.name:
        return 'Say the person\'s name';
      case VoiceRelativeStep.relationship:
        return 'Say the relationship (e.g., mother, friend)';
      case VoiceRelativeStep.photo:
        return 'Say "take photo" or "skip"';
      case VoiceRelativeStep.notes:
        return 'Say notes or "skip"';
      case VoiceRelativeStep.confirm:
        return 'Say "save" or "cancel"';
      default:
        return 'Speak clearly';
    }
  }

  String _getStatusMessage() {
    switch (_currentStep) {
      case VoiceRelativeStep.welcome:
        return 'Starting voice-guided flow...';
      case VoiceRelativeStep.saving:
        return 'Saving relative information...';
      case VoiceRelativeStep.complete:
        return 'Relative added successfully!';
      default:
        return 'Processing...';
    }
  }
}
