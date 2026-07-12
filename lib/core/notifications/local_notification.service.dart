import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  static const _searchResultNotificationId = 2001;
  static const _weeklySearchReminderId = 2002;
  static const _phoneRemindersEnabledKey = 'korascope_phone_reminders_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> scheduleCompetitorSearchResultReminder() async {
    await _safe(() async {
      if (!await arePhoneRemindersEnabled()) return;
      await initialize();
      await _plugin.zonedSchedule(
        _searchResultNotificationId,
        'Recherche terminée ?',
        'Allez vérifier si de nouveaux concurrents ont été trouvés.',
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 30)),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    });
  }

  Future<void> scheduleWeeklyCompetitorSearchReminder() async {
    await _safe(() async {
      if (!await arePhoneRemindersEnabled()) return;
      await initialize();
      await _plugin.zonedSchedule(
        _weeklySearchReminderId,
        'Gardez votre veille à jour',
        'Un nouveau concurrent peut apparaître entre temps. Lancez une recherche pour rester à jour.',
        _nextMondayAtNine(),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    });
  }

  Future<bool> arePhoneRemindersEnabled() async {
    final value = await _storage.read(key: _phoneRemindersEnabledKey);
    return value != 'false';
  }

  Future<void> setPhoneRemindersEnabled(bool enabled) async {
    await _storage.write(
      key: _phoneRemindersEnabledKey,
      value: enabled ? 'true' : 'false',
    );
    if (enabled) {
      await scheduleWeeklyCompetitorSearchReminder();
    } else {
      await cancelPhoneReminders();
    }
  }

  Future<void> cancelPhoneReminders() async {
    await _safe(() async {
      await initialize();
      await _plugin.cancel(_searchResultNotificationId);
      await _plugin.cancel(_weeklySearchReminderId);
    });
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'korascope_competitor_watch',
      'Veille concurrentielle',
      channelDescription: 'Rappels liés à la veille des concurrents',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  tz.TZDateTime _nextMondayAtNine() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    final daysUntilMonday = (DateTime.monday - scheduled.weekday) % 7;
    scheduled = scheduled.add(Duration(days: daysUntilMonday));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  Future<void> _requestPermissions() async {
    await _safe(() async {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    });
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      // Tests, web, or unsupported platforms should not break core flows.
    } catch (_) {
      // Notifications are helpful, but never critical enough to block the app.
    }
  }
}
