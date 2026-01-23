import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _tzReady = false;
  late tz.Location _location;

  Future<void> init() async {
    await _ensureTimeZoneReady();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _ensureTimeZoneReady() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();

    _location = tz.getLocation('Europe/Malta');

    tz.setLocalLocation(_location);

    _tzReady = true;
  }

  Future<void> scheduleExpiryReminder({
    required int notificationId,
    required String itemName,
    required DateTime expiryDate,
    int daysBefore = 2,
  }) async {
    await _ensureTimeZoneReady();

    final targetDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      9,
      0,
    ).subtract(Duration(days: daysBefore));

    if (!targetDate.isAfter(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Reminders',
      channelDescription: 'Notifications for items nearing expiry',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      notificationId,
      'Pantry reminder',
      '$itemName is expiring soon.',
      tz.TZDateTime.from(targetDate, _location),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
