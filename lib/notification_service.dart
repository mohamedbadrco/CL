import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import './database_helper.dart'; // For Event class
import 'package:alarm/alarm.dart'; // Import for the new alarm package
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// Import permission_handler

// Initialize the flutter_local_notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'event_channel_id',
      'Event Reminders',
      channelDescription: 'Notifications for upcoming events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

const DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

const NotificationDetails notificationDetails = NotificationDetails(
  android: androidNotificationDetails,
  iOS: darwinNotificationDetails,
  macOS: darwinNotificationDetails,
);

Future<void> initializeNotifications() async {
  tz.initializeTimeZones();

  if (Platform.isAndroid) {
    // Request Notification Permission (Android 13+)
    var notificationStatus = await Permission.notification.status;
    print("[Init] Initial Notification Permission Status: $notificationStatus");
    if (notificationStatus.isDenied || !notificationStatus.isGranted) {
      // More explicit check
      print(
        "[Init] Notification permission not granted or denied. Requesting...",
      );
      notificationStatus = await Permission.notification.request();
      print(
        "[Init] Notification Permission Status AFTER request: $notificationStatus",
      );
    }
    if (notificationStatus.isPermanentlyDenied) {
      print(
        "[Init] Notification permission permanently denied. Please enable it in settings.",
      );
    } else if (!notificationStatus.isGranted) {
      print("[Init] Notification permission was not granted during init.");
    } else {
      print("[Init] Notification permission is granted (checked during init).");
    }

    // Request Schedule Exact Alarm Permission (Android 12+)
    var scheduleExactAlarmStatus = await Permission.scheduleExactAlarm.status;
    print(
      "[Init] Initial Schedule Exact Alarm Permission Status: $scheduleExactAlarmStatus",
    );
    if (scheduleExactAlarmStatus.isDenied ||
        !scheduleExactAlarmStatus.isGranted) {
      // More explicit check
      print(
        "[Init] Schedule exact alarm permission not granted or denied. Requesting...",
      );
      scheduleExactAlarmStatus = await Permission.scheduleExactAlarm.request();
      print(
        "[Init] Schedule Exact Alarm Permission Status AFTER request: $scheduleExactAlarmStatus",
      );
    }
    if (scheduleExactAlarmStatus.isPermanentlyDenied) {
      print(
        "[Init] Schedule exact alarm permission permanently denied. Please enable it in settings.",
      );
    } else if (!scheduleExactAlarmStatus.isGranted) {
      print(
        "[Init] Schedule exact alarm permission was not granted during init. Alarms may not be precise.",
      );
    } else {
      print(
        "[Init] Schedule exact alarm permission is granted (checked during init).",
      );
    }
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
          final String? payload = notificationResponse.payload;
          if (payload != null) {
            debugPrint('flutter_local_notifications payload: $payload');
          }
        },
    onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
  );

  try {
    await Alarm.init();
    print('Alarm package initialized successfully.');
  } catch (e) {
    print('Error initializing alarm package: $e');
  }
  print('Notification/Alarm services initialized');
}

Future<void> scheduleEventNotification(Event event) async {
  if (event.id == null) {
    print("Event ID is null, cannot schedule alarm for title: ${event.title}");
    return;
  }

  if (!event.scheduleAlarm) {
    print(
      'Alarm not scheduled for event "${event.title}" (ID: ${event.id}) as per user preference.',
    );
    await cancelEventNotification(event.id!);
    return;
  }

  if (Platform.isAndroid) {
    print("--- Checking permissions for scheduling event: ${event.title} ---");
    // 1. Check/Request Notification Permission
    var initialNotificationStatus = await Permission.notification.status;
    print(
      "[Schedule] Current Notification Permission Status: $initialNotificationStatus",
    );

    if (!initialNotificationStatus.isGranted) {
      print(
        "[Schedule] Notification permission NOT currently granted. Requesting...",
      );
      var newNotificationStatus = await Permission.notification.request();
      print(
        "[Schedule] Notification Permission Status AFTER request: $newNotificationStatus",
      );

      if (newNotificationStatus.isPermanentlyDenied) {
        print(
          "[Schedule] Notification permission permanently denied. Cannot schedule. Please enable in settings.",
        );
        // Optionally: openAppSettings();
        return;
      }
      if (!newNotificationStatus.isGranted) {
        print(
          "[Schedule] Notification permission was STILL NOT granted after request. Cannot schedule for event: ${event.title}",
        );
        return;
      }
      print("[Schedule] Notification permission granted upon this request.");
    } else {
      print("[Schedule] Notification permission was ALREADY granted.");
    }

    // 2. Check/Request Schedule Exact Alarm Permission
    var initialScheduleExactAlarmStatus =
        await Permission.scheduleExactAlarm.status;
    print(
      "[Schedule] Current Schedule Exact Alarm Permission Status: $initialScheduleExactAlarmStatus",
    );

    if (!initialScheduleExactAlarmStatus.isGranted) {
      print(
        "[Schedule] Schedule exact alarm permission NOT currently granted. Requesting...",
      );
      var newScheduleExactAlarmStatus = await Permission.scheduleExactAlarm
          .request();
      print(
        "[Schedule] Schedule Exact Alarm Permission Status AFTER request: $newScheduleExactAlarmStatus",
      );

      if (newScheduleExactAlarmStatus.isPermanentlyDenied) {
        print(
          "[Schedule] Schedule exact alarm permission permanently denied. Alarms may not be precise. Enable in settings.",
        );
        // Optionally: openAppSettings();
      } else if (!newScheduleExactAlarmStatus.isGranted) {
        print(
          "[Schedule] Schedule exact alarm permission was STILL NOT granted after request. Alarms may not be precise for event: ${event.title}",
        );
      } else {
        print(
          "[Schedule] Schedule exact alarm permission granted upon this request.",
        );
      }
    } else {
      print("[Schedule] Schedule exact alarm permission was ALREADY granted.");
    }
    print("--- Finished permission checks for event: ${event.title} ---");
  }

  final DateTime eventStartTime = event.startTimeAsDateTime;
  final DateTime alarmTime = eventStartTime.subtract(
    const Duration(minutes: 10),
  );
  print(
    'Scheduling alarm for event: "${event.title}" (ID: ${event.id}) at $alarmTime.',
  );

  if (alarmTime.isBefore(DateTime.now())) {
    print(
      "Alarm time for event '${event.title}' is in the past. Not scheduling alarm.",
    );
    return;
  }

  try {
    final alarmSettings = AlarmSettings(
      id: event.id!,
      dateTime: alarmTime,
      assetAudioPath: 'assets/good_morning.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Upcoming Event: ${event.title}',
        body: 'Starts at ${DateFormat.jm().format(eventStartTime)}',
        stopButton: 'Stop the alarm',
        icon: 'notification_icon',
        iconColor: Color(0xff862778),
      ),
    );
    await Alarm.set(alarmSettings: alarmSettings);
    print(
      'Alarm scheduled via alarm package for event "${event.title}" (ID: ${event.id}) at $alarmTime',
    );
  } catch (e) {
    print(
      'Error scheduling alarm for event ID ${event.id} using alarm package: $e',
    );
  }
}

Future<void> cancelEventNotification(int eventId) async {
  try {
    await Alarm.stop(eventId);
    print('Alarm cancelled for event ID $eventId using alarm package.');
  } catch (e) {
    print(
      'Error cancelling alarm for event ID $eventId using alarm package: $e',
    );
  }
}

Future<void> cancelAllNotifications() async {
  try {
    await Alarm.stopAll();
    print('All alarms cancelled using alarm package.');
  } catch (e) {
    print('Error cancelling all alarms using alarm package: $e');
  }
}

@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse notificationResponse) {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    debugPrint('Background flutter_local_notification payload: $payload');
  }
}

Future<void> cleanupCompletedEventNotifications() async {
  final dbHelper = DatabaseHelper.instance;
  final List<Event> allEvents = await dbHelper.getAllEvents();
  final DateTime now = DateTime.now();
  int cleanedCount = 0;
  for (Event event in allEvents) {
    if (event.id != null && event.endTimeAsDateTime.isBefore(now)) {
      print(
        "[Cleanup] Cleaning up completed event's alarm: ${event.title} (ID: ${event.id})",
      );
      await Alarm.stop(
        event.id!,
      ); // Assuming Alarm.stop() is idempotent and won't error if no alarm found
      cleanedCount++;
    }
  }
  if (cleanedCount > 0) {
    print("[Cleanup] Cleaned up $cleanedCount completed event alarms.");
  } else {
    print("[Cleanup] No completed event alarms found to clean up.");
  }
}
