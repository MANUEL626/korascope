import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalSyncPlan {
  final bool competitors;
  final bool reports;

  const LocalSyncPlan({required this.competitors, required this.reports});

  bool get hasWork => competitors || reports;
}

class LocalSyncService {
  LocalSyncService._();

  static final instance = LocalSyncService._();

  static const _competitorsKey = 'korascope_last_competitor_sync_day';
  static const _reportsKey = 'korascope_last_report_sync_week';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<LocalSyncPlan> consumeDueSyncs({DateTime? now}) async {
    final current = now ?? DateTime.now();
    if (current.hour < 8) {
      return const LocalSyncPlan(competitors: false, reports: false);
    }

    try {
      final today = _dayKey(current);
      final week = _weekKey(current);
      final lastCompetitorSync = await _storage.read(key: _competitorsKey);
      final lastReportSync = await _storage.read(key: _reportsKey);

      final shouldSyncCompetitors = lastCompetitorSync != today;
      final shouldSyncReports =
          _isAfterThisWeeksMondayAtEight(current) && lastReportSync != week;

      if (shouldSyncCompetitors) {
        await _storage.write(key: _competitorsKey, value: today);
      }
      if (shouldSyncReports) {
        await _storage.write(key: _reportsKey, value: week);
      }

      return LocalSyncPlan(
        competitors: shouldSyncCompetitors,
        reports: shouldSyncReports,
      );
    } on MissingPluginException {
      return const LocalSyncPlan(competitors: false, reports: false);
    } catch (_) {
      return const LocalSyncPlan(competitors: false, reports: false);
    }
  }

  bool _isAfterThisWeeksMondayAtEight(DateTime value) {
    final monday = value.subtract(Duration(days: value.weekday - 1));
    final mondayAtEight = DateTime(monday.year, monday.month, monday.day, 8);
    return !value.isBefore(mondayAtEight);
  }

  String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _weekKey(DateTime value) {
    final monday = value.subtract(Duration(days: value.weekday - 1));
    return _dayKey(monday);
  }
}
