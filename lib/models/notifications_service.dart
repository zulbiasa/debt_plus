import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';


class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  //INITIALIZED
  Future<void> initNotification() async {
    if (_isInitialized) return; //prevent re-initialization

    //init timezone handling
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));


    //prepare android init settings
    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    //prepare ios init settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    //prepare settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    //initialize
    await notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  // REQUEST PERMISSIONS
  Future<void> requestPermissions() async {
    if (!_isInitialized) {
      await initNotification(); // Ensure initialized before requesting
    }

    // Request iOS permissions specifically (already handled in init for iOS if set to true)
    if (Platform.isIOS) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // For Android, we can use permission_handler package for more granular control if needed
      // For basic notifications, the plugin might handle runtime permissions automatically in some cases.
      // However, for explicit control and future-proofing, consider using permission_handler.
      // Example using permission_handler (you'll need to add it to pubspec.yaml):
      var status = await Permission.notification.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.notification.request();
      }
      if (status.isGranted) {
        print('Notification permissions granted on Android');
      } else {
        print('Notification permissions denied on Android');
      }
    }
  }

  //NOTIFICATION DETAILS SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'debt_plus_noti',
        'Debt Plus Notifications',
        channelDescription: 'Debt Plus Notifications Channels',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }

  //SCHEDULING NOTIFICATION
  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    //Get current date/time in device's local timezone
    final now = tz.TZDateTime.now(tz.local);

    //Create a DateTime with the provided hour and minute
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),

      //IOS Specific: use exact time specified (vs relative time)
      uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,

      //Android specific
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      //if want... use this to repeat notification
      //matchDateTimeComponents: DateTimeComponents.time,
    );
    print('Notification scheduled for $scheduledDate');
  }

  //Cancel all Notification
  Future<void> cancelAllNoti() async {
    await notificationsPlugin.cancelAll();
  }

  //ON NOTI TAP
}
