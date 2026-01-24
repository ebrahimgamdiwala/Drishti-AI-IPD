/// Drishti App - Profile Screen
///
/// User profile matching UI reference image 5.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.myProfile,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 20),

                // Avatar
                Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.lightBackground,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 16),

                // Name
                Text(
                  user?.name ?? 'John Doe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 4),

                // Email
                Text(
                  user?.email ?? 'john@example.com',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                const SizedBox(height: 32),

                // Menu items
                Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _ProfileMenuItem(
                              icon: Icons.person_outline,
                              title: AppStrings.profile,
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            _ProfileMenuItem(
                              icon: Icons.favorite_outline,
                              title: 'Favorites',
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            _ProfileMenuItem(
                              icon: Icons.contact_emergency_outlined,
                              title: AppStrings.emergencyContacts,
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            _ProfileMenuItem(
                              icon: Icons.people_outline,
                              title: AppStrings.connectedUsers,
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            _ProfileMenuItem(
                              icon: Icons.privacy_tip_outlined,
                              title: AppStrings.privacyPolicy,
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            _ProfileMenuItem(
                              icon: Icons.settings_outlined,
                              title: AppStrings.settings,
                              onTap: () => Navigator.pop(context),
                            ),
                            const Divider(height: 1),
                            _ProfileMenuItem(
                              icon: Icons.help_outline,
                              title: AppStrings.help,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _ProfileMenuItem(
                      icon: Icons.logout,
                      title: AppStrings.logout,
                      isDestructive: true,
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : null;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primaryBlue, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}
