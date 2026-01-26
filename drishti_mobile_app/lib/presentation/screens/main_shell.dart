/// Drishti App - Main Shell
///
/// Bottom navigation container for main screens.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'relatives/relatives_screen.dart';
import 'activity/activity_screen.dart';
import 'settings/settings_screen.dart';
import 'vlm/vlm_chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DashboardScreen(),
    VLMChatScreen(),
    RelativesScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'AI Vision',
    ),
    _NavItem(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Relatives',
    ),
    _NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Activity',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassDarkSurface
                    : AppColors.glassWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.glassDarkBorder
                        : AppColors.glassBorder,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                minimum: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          _navItems.length,
                          (index) => _buildNavItem(index, isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];

    return Semantics(
      label: item.label,
      selected: isSelected,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                size: 26,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
