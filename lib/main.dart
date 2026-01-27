import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_pantry/services/analytics_service.dart';
import 'app/smart_pantry_app.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await AnalyticsService.instance.logAppStarted();
  await NotificationService.instance.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAnalytics.instance.logEvent(
    name: 'debug_view_test',
    parameters: {'source': 'emulator'},
  );
  runApp(const ProviderScope(child: SmartPantryApp()));
}
