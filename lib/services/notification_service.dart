import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const bool kPresentationDebugMode = true;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _tzReady = false;
  late tz.Location _location;

  static const String _channelId = 'expiry_channel';
  static const String _channelName = 'Expiry Reminders';
  static const String _channelDesc = 'Notifications for items nearing expiry';

  Future<void> init() async {
    await _ensureTimeZoneReady();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();
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

    final tz.TZDateTime scheduled;

    if (kPresentationDebugMode) {
      scheduled = tz.TZDateTime.now(_location).add(const Duration(seconds: 30));
    } else {
      final targetDate = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        9,
        0,
      ).subtract(Duration(days: daysBefore));

      if (!targetDate.isAfter(DateTime.now())) return;
      scheduled = tz.TZDateTime.from(targetDate, _location);
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.zonedSchedule(
      notificationId,
      'Pantry reminder',
      '$itemName is expiring soon.',
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
