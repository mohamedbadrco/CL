import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz; // Keep if other parts still use tz.TZDateTime directly
import 'package:intl/intl.dart';
import './database_helper.dart'; // For Event class
import 'package:alarm/alarm.dart'; // Import for the new alarm package
import 'package:flutter/material.dart';

// Initialize the flutter_local_notifications plugin (can still be used for other types of notifications)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// bool _exactAlarmsPermitted = false; // This was for flutter_local_notifications exact alarms

// --- flutter_local_notifications specific details (can be kept for other notifications) ---
const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'event_channel_id', // Channel ID
      'Event Reminders', // Channel name
      channelDescription: 'Notifications for upcoming events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound:
          true, // This might be overridden by the alarm package for alarms
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
// --- End flutter_local_notifications specific details ---

Future<void> initializeNotifications() async {
  // Initialize timezone data - MUST be called before scheduling (if flutter_local_notifications uses it)
  tz.initializeTimeZones();

  // Initialize flutter_local_notifications (for non-alarm notifications if any)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
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
            debugPrint('notification payload: $payload');
          }
        },
    onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
  );
  await _createNotificationChannel(); // For flutter_local_notifications
  // _requestPermissions(); // Original permissions for flutter_local_notifications

  // Initialize the Alarm package
  try {
    await Alarm.init(); // Or Alarm.initialize() - CHECK PACKAGE DOCS
    print('Alarm package initialized successfully.');
  } catch (e) {
    print('Error initializing alarm package: $e');
  }

  print('Notification/Alarm services initialized');
}

// Keep this for flutter_local_notifications if other general notifications are used
// Future<void> _requestPermissions() async {
//   flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         IOSFlutterLocalNotificationsPlugin
//       >()
//       ?.requestPermissions(alert: true, badge: true, sound: true);
//   final androidPlugin = flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >();
//   await androidPlugin
//       ?.requestNotificationsPermission(); // For Android 13+ (notifications)
//   // The 'alarm' package should handle its own exact alarm permissions if needed.
//   // bool exactAlarmsPermittedFlNotif = await androidPlugin?.requestExactAlarmsPermission() ?? false;
// }

// Keep this for flutter_local_notifications if other general notifications are used
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'event_channel_id', // Channel ID
    'Event Reminders', // Channel name
    description: 'Notifications for upcoming events',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

Future<void> scheduleEventNotification(Event event) async {
  if (event.id == null) {
    print("Event ID is null, cannot schedule alarm for title: ${event.title}");
    return;
  }

  final DateTime eventStartTime = event.startTimeAsDateTime;
  // Let's set the alarm 10 minutes before the event for consistency with old behavior
  // Adjust this as needed (e.g., to eventStartTime directly)
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
      assetAudioPath: 'assets/good_morning.mp3', // MODIFIED: Using your specified asset
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS, // Make sure dart:io is imported for Platform
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
        icon: 'notification_icon', // Ensure this drawable resource exists in android/app/src/main/res/drawable*
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
    await Alarm.stop(eventId); // VERIFY THIS METHOD NAME WITH PACKAGE DOCS
    print('Alarm cancelled for event ID $eventId using alarm package.');
  } catch (e) {
    print(
      'Error cancelling alarm for event ID $eventId using alarm package: $e',
    );
  }
}

Future<void> cancelAllNotifications() async {
  try {
    await Alarm.stopAll(); // VERIFY THIS METHOD NAME WITH PACKAGE DOCS
    print('All alarms cancelled using alarm package.');
  } catch (e) {
    print('Error cancelling all alarms using alarm package: $e');
  }
}

// This function remains for flutter_local_notifications (e.g., if you have other types of notifications)
Future<void> showTestNotification() async {
  await flutterLocalNotificationsPlugin.show(
    0, // ID for test notification
    'Test Flutter Local Notification',
    'This is a test of flutter_local_notifications plugin.',
    notificationDetails, // Uses the FLN details defined at the top
  );
  print('Test flutter_local_notification shown');
}

Future<List<Map<String, dynamic>>> getPendingNotificationsWithDetails() async {
  print(
    'getPendingNotificationsWithDetails: This list is for flutter_local_notifications only.',
  );
  print('Alarms set by the \'alarm\' package are typically not listed here.');

  final List<PendingNotificationRequest> pendingLocalNotifications =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  print(
    'Pending flutter_local_notifications: ${pendingLocalNotifications.length}',
  );

  List<Map<String, dynamic>> detailedList = [];
  for (var fln in pendingLocalNotifications) {
    detailedList.add({
      'id': fln.id,
      'title': fln.title ?? 'N/A',
      'body': fln.body ?? 'N/A',
      'payload': fln.payload,
      'type': 'Flutter Local Notification',
    });
  }
  return detailedList;
}

@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse notificationResponse) {
  // This callback is for flutter_local_notifications
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    debugPrint('Background flutter_local_notification payload: $payload');
  }
}

Future<void> cleanupCompletedEventNotifications() async {
  print(
    'cleanupCompletedEventNotifications: This function needs review for the new alarm package.',
  );
  print(
    'It currently attempts to clean up flutter_local_notifications, not alarms from the \'alarm\' package.',
  );
}
