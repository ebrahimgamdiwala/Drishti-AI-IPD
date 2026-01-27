/// Permissions Request Screen
///
/// Requests necessary permissions for camera and microphone.
library;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/vlm_provider.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/buttons/gradient_button.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _microphoneGranted = micStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => _isChecking = true);

    // Request camera permission
    if (!_cameraGranted) {
      final cameraStatus = await Permission.camera.request();
      _cameraGranted = cameraStatus.isGranted;
    }

    // Request microphone permission
    if (!_microphoneGranted) {
      final micStatus = await Permission.microphone.request();
      _microphoneGranted = micStatus.isGranted;
    }

    setState(() => _isChecking = false);

    // If both granted, check model status and proceed
    if (_cameraGranted && _microphoneGranted) {
      await _checkModelAndProceed();
    }
  }

  Future<void> _checkModelAndProceed() async {
    final vlmProvider = context.read<VLMProvider>();
    final modelsDownloaded = await vlmProvider.areModelsDownloaded;

    if (!mounted) return;

    if (modelsDownloaded) {
      // Models already exist, go directly to main screen
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else {
      // Models don't exist, go to download screen
      Navigator.pushReplacementNamed(context, '/model-download');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allGranted = _cameraGranted && _microphoneGranted;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Permissions Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Drishti needs access to your camera and microphone to provide vision assistance and voice commands.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Permission items
              _PermissionItem(
                icon: Icons.camera_alt,
                title: 'Camera',
                description: 'To analyze your surroundings',
                isGranted: _cameraGranted,
              ),

              const SizedBox(height: 16),

              _PermissionItem(
                icon: Icons.mic,
                title: 'Microphone',
                description: 'For voice commands and navigation',
                isGranted: _microphoneGranted,
              ),

              const Spacer(),

              // Continue button
              if (allGranted)
                GradientButton(
                  text: 'Continue',
                  onPressed: _checkModelAndProceed,
                  isLoading: _isChecking,
                )
              else
                GradientButton(
                  text: 'Grant Permissions',
                  onPressed: _requestPermissions,
                  isLoading: _isChecking,
                ),

              const SizedBox(height: 16),

              // Skip button (not recommended)
              if (!allGranted)
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.main);
                  },
                  child: Text(
                    'Skip (Not Recommended)',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.success : AppColors.primaryBlue,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Status icon
          Icon(
            isGranted ? Icons.check_circle : Icons.circle_outlined,
            color: isGranted ? AppColors.success : AppColors.textSecondaryLight,
            size: 24,
          ),
        ],
      ),
    );
  }
}
