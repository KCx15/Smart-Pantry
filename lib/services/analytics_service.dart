import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _a => FirebaseAnalytics.instance;

  Future<void> logAppStarted() async {
    try {
      await _a.logEvent(
        name: 'debug_app_started',
        parameters: {'platform': kIsWeb ? 'web' : 'android'},
      );
    } catch (_) {}
  }

  Future<void> itemAdded({
    required String itemId,
    required bool reminderEnabled,
  }) async {
    try {
      await _a.logEvent(
        name: 'item_added',
        parameters: {
          'item_id': itemId,
          'reminder_enabled': reminderEnabled ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  Future<void> itemDeleted({required String itemId}) async {
    try {
      await _a.logEvent(name: 'item_deleted', parameters: {'item_id': itemId});
    } catch (_) {}
  }

  Future<void> itemUpdated({required String itemId}) async {
    try {
      await _a.logEvent(name: 'item_updated', parameters: {'item_id': itemId});
    } catch (_) {}
  }

  Future<void> reminderScheduled({required String itemId}) async {
    try {
      await _a.logEvent(
        name: 'reminder_scheduled',
        parameters: {'item_id': itemId},
      );
    } catch (_) {}
  }
}
