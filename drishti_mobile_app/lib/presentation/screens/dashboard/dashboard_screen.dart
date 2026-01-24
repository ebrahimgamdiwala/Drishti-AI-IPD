/// Drishti App - Dashboard Screen
///
/// Stats cards overview matching UI reference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/cards/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Simulated stats data
  final Map<String, dynamic> _stats = {
    'battery': 85,
    'connection': true,
    'alerts': 3,
    'interactions': 12,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.dashboard,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Refresh stats
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 8),

              Text(
                AppStrings.todayStats,
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Date selector (horizontal scroll)
              _buildDateSelector().animate().fadeIn(
                delay: 200.ms,
                duration: 300.ms,
              ),

              const SizedBox(height: 24),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Slightly taller cards to avoid overflow on small screens
                childAspectRatio: 0.95,
                children: [
                  StatsCard(
                        title: AppStrings.batteryLevel,
                        value: '${_stats['battery']}%',
                        icon: Icons.battery_charging_full,
                        iconColor: _stats['battery'] > 50
                            ? AppColors.success
                            : AppColors.warning,
                      )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),

                  StatsCard(
                        title: AppStrings.connectionStatus,
                        value: _stats['connection'] ? 'Connected' : 'Offline',
                        icon: _stats['connection']
                            ? Icons.wifi
                            : Icons.wifi_off,
                        iconColor: _stats['connection']
                            ? AppColors.success
                            : AppColors.error,
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),

                  StatsCard(
                        title: AppStrings.alertsToday,
                        value: '${_stats['alerts']}',
                        icon: Icons.warning_amber,
                        iconColor: AppColors.warning,
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),

                  StatsCard(
                        title: AppStrings.interactions,
                        value: '${_stats['interactions']}',
                        icon: Icons.touch_app,
                        iconColor: AppColors.primaryBlue,
                      )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Activity Section
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ).animate().fadeIn(delay: 700.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // Activity list
              _buildActivityItem(
                'Obstacle detected',
                '2 min ago',
                Icons.remove_red_eye,
                AppColors.warning,
              ).animate().fadeIn(delay: 800.ms, duration: 300.ms),

              _buildActivityItem(
                'Voice command processed',
                '15 min ago',
                Icons.mic,
                AppColors.primaryBlue,
              ).animate().fadeIn(delay: 900.ms, duration: 300.ms),

              _buildActivityItem(
                'Person identified: John',
                '1 hour ago',
                Icons.face,
                AppColors.success,
              ).animate().fadeIn(delay: 1000.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isToday = day.day == today.day;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 55,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primaryBlue : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: !isToday
                  ? Border.all(color: AppColors.lightBorder)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNames[day.weekday - 1],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
        ],
      ),
    );
  }
}
