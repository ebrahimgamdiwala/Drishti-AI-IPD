/// Centralized app activity logging with retention and automatic pruning.
library;

import 'dart:math';

import '../models/activity_model.dart';
import 'storage_service.dart';

class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();

  factory ActivityLogService() => _instance;

  ActivityLogService._internal();

  final StorageService _storage = StorageService();
  final List<VoidCallback> _listeners = <VoidCallback>[];

  List<ActivityModel> _logs = <ActivityModel>[];
  bool _isLoaded = false;

  static const Duration _importantRetention = Duration(days: 14);
  static const Duration _regularRetention = Duration(days: 2);
  static const int _maxLogCount = 300;
  static const Duration _dedupeWindow = Duration(seconds: 20);

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;

    _logs = _storage.getActivityLogs();
    _pruneOldLogs();
    _sortDescending();
    _isLoaded = true;
    await _persist();
  }

  Future<List<ActivityModel>> getLogs() async {
    await ensureLoaded();
    return List<ActivityModel>.unmodifiable(_logs);
  }

  Future<void> addLog({
    required ActivityType type,
    required String title,
    required String description,
    String? severity,
    bool isImportant = false,
    Map<String, dynamic>? metadata,
  }) async {
    await ensureLoaded();

    final now = DateTime.now();
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    if (normalizedTitle.isEmpty || normalizedDescription.isEmpty) {
      return;
    }

    final isDuplicate = _logs.any((entry) {
      if (entry.type != type) return false;
      if (entry.title != normalizedTitle) return false;
      if (entry.description != normalizedDescription) return false;
      return now.difference(entry.timestamp).abs() <= _dedupeWindow;
    });

    if (isDuplicate) {
      return;
    }

    _logs.add(
      ActivityModel(
        id: _buildId(now),
        type: type,
        title: normalizedTitle,
        description: normalizedDescription,
        severity: severity,
        timestamp: now,
        metadata: metadata,
        isImportant: isImportant,
      ),
    );

    _pruneOldLogs();
    _sortDescending();
    await _persist();
    _notify();
  }

  Future<void> clearLogs({bool keepImportant = true}) async {
    await ensureLoaded();

    if (keepImportant) {
      _logs = _logs.where((log) => log.isImportant).toList(growable: true);
    } else {
      _logs = <ActivityModel>[];
    }

    _sortDescending();
    await _persist();
    _notify();
  }

  Future<void> runMaintenance() async {
    await ensureLoaded();
    _pruneOldLogs();
    _sortDescending();
    await _persist();
    _notify();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  Future<void> _persist() async {
    await _storage.saveActivityLogs(_logs);
  }

  void _sortDescending() {
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _pruneOldLogs() {
    final now = DateTime.now();

    _logs = _logs
        .where((log) {
          final age = now.difference(log.timestamp);
          final ttl = log.isImportant ? _importantRetention : _regularRetention;
          return age <= ttl;
        })
        .toList(growable: true);

    _sortDescending();

    if (_logs.length > _maxLogCount) {
      final important = _logs
          .where((l) => l.isImportant)
          .toList(growable: true);
      final regular = _logs.where((l) => !l.isImportant).toList(growable: true);

      final allowedRegular = max(0, _maxLogCount - important.length);
      final trimmedRegular = regular
          .take(allowedRegular)
          .toList(growable: false);

      _logs = <ActivityModel>[...important, ...trimmedRegular];
      _sortDescending();
    }
  }

  String _buildId(DateTime now) {
    final micros = now.microsecondsSinceEpoch;
    final random = Random().nextInt(1 << 20).toRadixString(16);
    return '$micros-$random';
  }
}

typedef VoidCallback = void Function();
