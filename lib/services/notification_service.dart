import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../repositories/auth_repository.dart';
import '../views/home/home_view.dart';
import 'service_locator.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize time zones
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone, defaulting to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Setup initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap();
      },
    );

    // 3. Schedule the notifications based on saved preferences
    final prefs = await SharedPreferences.getInstance();
    final dailyRemindersEnabled = prefs.getBool('daily_reminders_enabled') ?? true;
    final meditationRemindersEnabled = prefs.getBool('meditation_reminders_enabled') ?? false;

    if (dailyRemindersEnabled) {
      await scheduleDailyTenAMNotification();
    } else {
      await cancelDailyReminder();
    }

    if (meditationRemindersEnabled) {
      await scheduleDailyMeditationReminder();
    } else {
      await cancelMeditationReminder();
    }
  }

  Future<void> requestPermissions() async {
    try {
      // For iOS
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // For Android 13+
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> scheduleDailyTenAMNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminder to practice mindfulness',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime scheduledDate = _nextInstanceOfTenAM();

    await _localNotifications.zonedSchedule(
      id: 1001, // Unique ID for morning reminder
      title: 'Daily Streak Reminder! 🔥',
      body: 'Keep your streak alive! Open MindFlow for a quick 3-minute mindfulness session.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Reoccur daily at 10:00 AM
    );

    debugPrint('Daily morning notification scheduled at: $scheduledDate');
  }

  tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 10, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(id: 1001);
    debugPrint('Daily morning notification (10 AM) cancelled.');
  }

  Future<void> scheduleDailyMeditationReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_meditation_channel',
      'Daily Meditations',
      channelDescription: 'Daily reminder to practice meditation',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime scheduledDate = _nextInstanceOfSixPM();

    await _localNotifications.zonedSchedule(
      id: 1002, // Unique ID for daily meditation reminder
      title: 'Mindful Evening 🧘',
      body: 'It\'s time for your daily meditation session. Take a moment to reset and unwind.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Daily meditation notification scheduled at: $scheduledDate');
  }

  tz.TZDateTime _nextInstanceOfSixPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelMeditationReminder() async {
    await _localNotifications.cancel(id: 1002);
    debugPrint('Daily meditation notification cancelled.');
  }

  void _handleNotificationTap() {
    final isLoggedIn = locator<AuthRepository>().isLoggedIn;
    if (isLoggedIn) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeView()),
        (route) => false,
      );
    }
  }
}
