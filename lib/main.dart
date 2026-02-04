import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/smart_pantry_app.dart';
import 'firebase_options.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await HiveService.init();
  await NotificationService.instance.init();

  await AnalyticsService.instance.logAppStarted();

  runApp(const ProviderScope(child: SmartPantryApp()));
}
