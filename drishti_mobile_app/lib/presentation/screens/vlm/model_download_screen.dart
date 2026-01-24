/// Model Download Screen
///
/// Shows download progress and status for the local VLM model.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/vlm_provider.dart';
import '../../../data/services/local_vlm_service.dart';

class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback? onModelReady;

  const ModelDownloadScreen({super.key, this.onModelReady});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  bool _isDownloading = false;
  String _statusMessage = 'Tap to start download';

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final vlm = context.read<VLMProvider>();
    final downloaded = await vlm.areModelsDownloaded;

    if (downloaded) {
      setState(() {
        _statusMessage = 'Model ready! Tap to initialize.';
      });
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Preparing download...';
    });

    try {
      final vlm = context.read<VLMProvider>();
      await vlm.ensureReady();

      if (mounted) {
        setState(() {
          _statusMessage = 'Model ready!';
          _isDownloading = false;
        });
        widget.onModelReady?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                const SizedBox(height: 48),
                _buildGlassIcon(isDark),
                const SizedBox(height: 32),

                // Title
                Text(
                  'AI Vision Model',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LLaVA Phi-3 Mini (INT4 Quantized)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),

                const SizedBox(height: 48),

                // Progress/Status Card
                _buildStatusCard(context, isDark),

                const Spacer(),

                // Download Button
                _buildDownloadButton(context, isDark),

                const SizedBox(height: 24),

                // Info text
                Text(
                  'Model size: ~3 GB\nRequires Wi-Fi recommended',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIcon(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.4),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isDark) {
    return Consumer<VLMProvider>(
      builder: (context, vlm, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.7),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                children: [
                  // Status Icon
                  _buildStatusIcon(vlm.status, isDark),
                  const SizedBox(height: 16),

                  // Status Text
                  Text(
                    _getStatusTitle(vlm.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),

                  // Progress Bar
                  if (vlm.status == VLMStatus.downloading ||
                      vlm.status == VLMStatus.loading) ...[
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: vlm.progress,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(vlm.progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(VLMStatus status, bool isDark) {
    IconData icon;
    Color color;

    switch (status) {
      case VLMStatus.uninitialized:
        icon = Icons.cloud_download_outlined;
        color = AppColors.primaryBlue;
      case VLMStatus.downloading:
        icon = Icons.downloading_rounded;
        color = AppColors.primaryBlue;
      case VLMStatus.loading:
        icon = Icons.memory_rounded;
        color = AppColors.gradientStart;
      case VLMStatus.ready:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
      case VLMStatus.error:
        icon = Icons.error_rounded;
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }

  String _getStatusTitle(VLMStatus status) {
    switch (status) {
      case VLMStatus.uninitialized:
        return 'Not Downloaded';
      case VLMStatus.downloading:
        return 'Downloading...';
      case VLMStatus.loading:
        return 'Loading Model...';
      case VLMStatus.ready:
        return 'Ready to Use';
      case VLMStatus.error:
        return 'Error Occurred';
    }
  }

  Widget _buildDownloadButton(BuildContext context, bool isDark) {
    return Consumer<VLMProvider>(
      builder: (context, vlm, _) {
        final isLoading =
            vlm.status == VLMStatus.downloading ||
            vlm.status == VLMStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primaryBlue.withValues(
                alpha: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    vlm.status == VLMStatus.ready
                        ? 'Model Ready'
                        : 'Download Model',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
