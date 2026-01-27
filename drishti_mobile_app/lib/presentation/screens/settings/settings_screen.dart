/// Drishti App - Settings Screen
///
/// App settings with light/dark mode toggle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/theme_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/voice_service.dart';
import '../../../routes/app_routes.dart';
import '../profile/profile_screen.dart';
import 'help_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';
import 'favorites_screen.dart';
import 'emergency_contacts_screen.dart';
import 'connected_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final VoiceService _voiceService = VoiceService();

  double _voiceSpeed = 0.5;
  bool _highContrast = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _voiceSpeed = _voiceService.speechRate;

    // Note: Screen announcement is handled by MainShell
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                AppStrings.settings,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              // Profile section
              _buildProfileCard(user?.name ?? 'User', user?.email ?? '')
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Connections Section
              _buildSectionHeader('Connections'),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _SettingTile(
                  icon: Icons.favorite_border,
                  title: 'Favorites',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _SettingTile(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency Contacts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _SettingTile(
                  icon: Icons.people_outline,
                  title: 'Connected Users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectedUsersScreen(),
                      ),
                    );
                  },
                ),
              ]).animate().fadeIn(delay: 150.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Appearance Section
              _buildSectionHeader(AppStrings.appearance),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _ThemeSelector(
                  currentTheme: themeProvider.themeType,
                  onChanged: (type) => themeProvider.setTheme(type),
                ),
              ]).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Voice Settings
              _buildSectionHeader(AppStrings.voiceSettings),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _SettingSlider(
                  title: AppStrings.voiceSpeed,
                  subtitle: _getSpeedLabel(_voiceSpeed),
                  value: _voiceSpeed,
                  onChanged: (value) async {
                    setState(() => _voiceSpeed = value);
                    await _voiceService.setSpeechRate(value);
                  },
                ),
              ]).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Accessibility
              _buildSectionHeader(AppStrings.accessibility),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _SettingToggle(
                  title: AppStrings.highContrast,
                  subtitle: 'Enhanced visibility for text and icons',
                  value: _highContrast,
                  onChanged: (value) {
                    setState(() => _highContrast = value);
                  },
                ),
                const Divider(),
                _SettingToggle(
                  title: AppStrings.largeText,
                  subtitle: 'Increase text size throughout the app',
                  value: false,
                  onChanged: (value) {},
                ),
              ]).animate().fadeIn(delay: 400.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Notifications
              _buildSectionHeader(AppStrings.notifications),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _SettingToggle(
                  title: 'Alert Notifications',
                  subtitle: 'Receive notifications for safety alerts',
                  value: _notifications,
                  onChanged: (value) {
                    setState(() => _notifications = value);
                  },
                ),
              ]).animate().fadeIn(delay: 500.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // About & Support
              _buildSettingsCard([
                _SettingTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
                const Divider(),
                _SettingTile(
                  icon: Icons.help_outline,
                  title: AppStrings.help,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                ),
                const Divider(),
                _SettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.privacyPolicy,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ]).animate().fadeIn(delay: 600.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Logout
              _buildSettingsCard([
                _SettingTile(
                  icon: Icons.logout,
                  title: AppStrings.logout,
                  isDestructive: true,
                  onTap: () => _handleLogout(context),
                ),
              ]).animate().fadeIn(delay: 700.ms, duration: 300.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
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
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  String _getSpeedLabel(double speed) {
    if (speed < 0.3) return 'Slow';
    if (speed < 0.6) return 'Normal';
    if (speed < 0.8) return 'Fast';
    return 'Very Fast';
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Capture references before async gap
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.logout();
      if (!mounted) return;
      navigator.pushReplacementNamed(AppRoutes.login);
    }
  }
}

// Theme Selector Widget
class _ThemeSelector extends StatelessWidget {
  final ThemeType currentTheme;
  final ValueChanged<ThemeType> onChanged;

  const _ThemeSelector({required this.currentTheme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ThemeOption(
                icon: Icons.light_mode,
                label: 'Light',
                isSelected: currentTheme == ThemeType.light,
                onTap: () => onChanged(ThemeType.light),
              ),
              const SizedBox(width: 12),
              _ThemeOption(
                icon: Icons.dark_mode,
                label: 'Dark',
                isSelected: currentTheme == ThemeType.dark,
                onTap: () => onChanged(ThemeType.dark),
              ),
              const SizedBox(width: 12),
              _ThemeOption(
                icon: Icons.settings_suggest,
                label: 'System',
                isSelected: currentTheme == ThemeType.system,
                onTap: () => onChanged(ThemeType.system),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.lightBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Setting Toggle Widget
class _SettingToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

// Setting Slider Widget
class _SettingSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primaryBlue,
              inactiveTrackColor: AppColors.lightBorder,
              thumbColor: AppColors.primaryBlue,
              overlayColor: AppColors.primaryBlue.withValues(alpha: 0.2),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

// Setting Tile Widget
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
