import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/notifications/local_notification.service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await LocalNotificationService.instance.initialize();
  await LocalNotificationService.instance
      .scheduleWeeklyCompetitorSearchReminder();
  runApp(const KoraScopeApp());
}
