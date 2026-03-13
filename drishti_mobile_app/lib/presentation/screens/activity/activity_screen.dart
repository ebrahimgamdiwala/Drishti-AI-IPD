/// Drishti App - Activity Screen
///
/// History timeline view.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/services/activity_log_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ActivityLogService _activityLogService = ActivityLogService();
  List<ActivityModel> _activities = <ActivityModel>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activityLogService.addListener(_onLogsUpdated);
    _loadActivities();
  }

  @override
  void dispose() {
    _activityLogService.removeListener(_onLogsUpdated);
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    final logs = await _activityLogService.getLogs();
    if (!mounted) return;
    setState(() {
      _activities = logs;
      _isLoading = false;
    });
  }

  void _onLogsUpdated() {
    if (!mounted) return;
    _loadActivities();
  }

  Future<void> _showHistoryActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Clear non-important logs'),
              onTap: () => Navigator.of(ctx).pop('clear_non_important'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear all logs'),
              onTap: () => Navigator.of(ctx).pop('clear_all'),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Run cleanup now'),
              onTap: () => Navigator.of(ctx).pop('cleanup'),
            ),
          ],
        ),
      ),
    );

    switch (action) {
      case 'clear_non_important':
        await _activityLogService.clearLogs(keepImportant: true);
        break;
      case 'clear_all':
        await _activityLogService.clearLogs(keepImportant: false);
        break;
      case 'cleanup':
        await _activityLogService.runMaintenance();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.history,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: _showHistoryActions,
                    icon: const Icon(Icons.filter_list),
                    tooltip: l10n.filter,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Activity list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _activities.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        final showDateHeader =
                            index == 0 ||
                            !_isSameDay(
                              _activities[index - 1].timestamp,
                              activity.timestamp,
                            );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 8,
                                ),
                                child: Text(
                                  _getDateHeader(activity.timestamp, l10n),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                ),
                              ),
                            _ActivityTile(activity: activity, l10n: l10n)
                                .animate()
                                .fadeIn(
                                  delay: Duration(milliseconds: 100 * index),
                                  duration: 300.ms,
                                )
                                .slideX(begin: 0.1, end: 0),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(l10n.noActivity, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.activityHistoryWillAppear,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateHeader(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return l10n.today;
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return l10n.yesterday;
    }
    return DateFormat('EEEE, MMM d').format(date);
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  final AppLocalizations l10n;

  const _ActivityTile({required this.activity, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: _getSeverityBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(), color: _getIconColor(), size: 22),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (activity.severity != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.severity!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getSeverityColor(),
                            ),
                          ),
                        ),
                      if (activity.isImportant)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.push_pin,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeString(activity.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (activity.type) {
      case ActivityType.scan:
        return Icons.camera_alt;
      case ActivityType.voice:
        return Icons.mic;
      case ActivityType.alert:
        return Icons.warning_amber;
      case ActivityType.identify:
        return Icons.face;
      case ActivityType.login:
        return Icons.login;
      default:
        return Icons.history;
    }
  }

  Color _getIconColor() {
    switch (activity.type) {
      case ActivityType.scan:
        return AppColors.primaryBlue;
      case ActivityType.voice:
        return AppColors.gradientEnd;
      case ActivityType.alert:
        return AppColors.warning;
      case ActivityType.identify:
        return AppColors.success;
      case ActivityType.login:
        return AppColors.info;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  Color _getSeverityColor() {
    switch (activity.severity?.toLowerCase()) {
      case 'critical':
        return AppColors.severityCritical;
      case 'high':
        return AppColors.severityHigh;
      case 'medium':
        return AppColors.severityMedium;
      case 'low':
        return AppColors.severityLow;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  Border? _getSeverityBorder() {
    if (activity.severity == 'critical') {
      return Border.all(
        color: AppColors.severityCritical.withValues(alpha: 0.5),
        width: 1,
      );
    }
    return null;
  }

  String _getTimeString(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat('h:mm a').format(time);
  }
}
