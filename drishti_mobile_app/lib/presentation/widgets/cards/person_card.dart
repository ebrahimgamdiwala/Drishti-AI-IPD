/// Drishti App - Person Card
/// 
/// Card widget for displaying relative/known person info.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/relative_model.dart';

class PersonCard extends StatelessWidget {
  final RelativeModel relative;
  final VoidCallback? onTap;
  final VoidCallback? onRecognize;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PersonCard({
    super.key,
    required this.relative,
    this.onTap,
    this.onRecognize,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: '${relative.name}, ${relative.relationship}. ${relative.hasFaceEmbeddings ? "Face registered" : "No face registered"}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(isDark),
                  
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          relative.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Relationship
                        Text(
                          relative.relationship,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Status and action buttons
                        Row(
                          children: [
                            // Recognize status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: relative.hasFaceEmbeddings
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    relative.hasFaceEmbeddings
                                        ? Icons.face
                                        : Icons.face_retouching_off,
                                    size: 14,
                                    color: relative.hasFaceEmbeddings
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    relative.hasFaceEmbeddings ? 'Registered' : 'Not Registered',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: relative.hasFaceEmbeddings
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Column(
                    children: [
                      _ActionButton(
                        icon: Icons.camera_alt,
                        tooltip: 'Recognize',
                        onPressed: onRecognize,
                      ),
                      const SizedBox(height: 4),
                      _ActionButton(
                        icon: Icons.info_outline,
                        tooltip: 'Info',
                        onPressed: onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    // Check for local image first
    final hasImage = relative.images.isNotEmpty;
    final localPath = hasImage ? relative.images.first.localPath : null;
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: !hasImage ? AppColors.cardGradient : null,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: localPath != null && File(localPath).existsSync()
            ? Image.file(
                File(localPath),
                fit: BoxFit.cover,
              )
            : hasImage
                ? Image.network(
                    relative.images.first.path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.lightInputFill,
      child: Center(
        child: Text(
          relative.name.isNotEmpty ? relative.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}
