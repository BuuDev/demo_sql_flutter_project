import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:demo_sql_flutter_project/models/task.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _exactAlarmsPermitted = false;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final String currentTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimezone));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {},
      );

      if (Platform.isAndroid) {
        _exactAlarmsPermitted = (await _checkExactAlarmsPermission())!;
      } else {
        _exactAlarmsPermitted = true;
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<bool?> _checkExactAlarmsPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      return androidPlugin?.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint('Error checking exact alarms permission: $e');
      return false;
    }
  }

  Future<void> requestPermissions() async {
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _exactAlarmsPermitted = (await _checkExactAlarmsPermission())!;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> openExactAlarmSettings() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
    }
  }

  Future<void> scheduleTaskReminder(Task task, {Duration? reminderTime}) async {
    if (task.id != null) {
      await cancelNotification(task.id!);
    }

    if (task.id != null) {
      try {
        final scheduledDate = reminderTime != null
            ? tz.TZDateTime.from(task.dueDate.subtract(reminderTime), tz.local)
            : tz.TZDateTime.from(task.dueDate, tz.local);

        if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            task.id!,
            'Task Reminder: ${task.title}',
            reminderTime != null
                ? 'Due in ${_formatDuration(reminderTime)}: ${task.dueDate.toString().substring(0, 16)}'
                : 'Due now: ${task.dueDate.toString().substring(0, 16)}',
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'task_reminder_channel',
                'Task Reminders',
                channelDescription: 'Notifications for task reminders',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: task.id.toString(),
          );

          debugPrint('Notification scheduled for: ${scheduledDate.toString()}');
        } else {
          debugPrint('Cannot schedule notification in the past');
        }
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
  }

  Future<void> showTestNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Channel for testing notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  Future<void> showTestScheduledNotification({
    required String title,
    required String body,
    int id = 0,
    int seconds = 5,
  }) async {
    try {
      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Channel for testing notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
          'Test scheduled notification set for: ${scheduledTime.toString()}');
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
    }
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours giờ ${minutes > 0 ? '$minutes phút' : ''}';
    } else {
      return '$minutes phút';
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  bool get exactAlarmsPermitted => _exactAlarmsPermitted;
}
