import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/smart_pantry_app.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await HiveService.init();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: SmartPantryApp()));
}
