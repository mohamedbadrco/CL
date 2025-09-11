import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz; // Keep if other parts still use tz.TZDateTime directly
import 'package:intl/intl.dart';
import './database_helper.dart'; // For Event class
import 'package:alarm/alarm.dart'; // Import for the new alarm package
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

// Initialize the flutter_local_notifications plugin (can still be used for other types of notifications, if any)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// --- flutter_local_notifications specific details (can be kept for other notifications, if any) ---
const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'event_channel_id', // Channel ID
      'Event Reminders', // Channel name
      channelDescription: 'Notifications for upcoming events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound:
          true,
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
  tz.initializeTimeZones();

  // Request Notification Permission (Android 13+)
  if (Platform.isAndroid) {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    if (status.isPermanentlyDenied) {
      // Consider guiding the user to app settings
      print("Notification permission permanently denied. Please enable it in settings.");
      // openAppSettings(); // This function from permission_handler can open app settings
    }
    if (!status.isGranted) {
        print("Notification permission was not granted.");
        // App can continue, but notifications from flutter_local_notifications
        // and potentially from the alarm package might not show.
    } else {
        print("Notification permission granted.");
    }

    // Request Schedule Exact Alarm Permission (Android 12+)
    // The `alarm` package might handle this internally if using a newer version,
    // or you might need to check if it can schedule exact alarms via native checks
    // if `Permission.scheduleExactAlarm.request()` isn't sufficient or causes issues.
    // For API 34+, user needs to grant this from settings manually if not a calendar/alarm clock app.
    // The `alarm` package itself might also have utilities or recommendations for this.
    if (await Permission.scheduleExactAlarm.isDenied) {
        var exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        if (exactAlarmStatus.isPermanentlyDenied) {
            print("Schedule exact alarm permission permanently denied. Please enable it in settings.");
            // openAppSettings();
        }
        if (!exactAlarmStatus.isGranted) {
            print("Schedule exact alarm permission was not granted. Alarms may not be precise.");
        } else {
            print("Schedule exact alarm permission granted.");
        }
    } else if (await Permission.scheduleExactAlarm.isGranted) {
        print("Schedule exact alarm permission already granted.");
    } else {
        print("Schedule exact alarm permission status: ${await Permission.scheduleExactAlarm.status}");
        // On Android 14+ (API 34+), this permission often needs to be enabled manually by the user
        // in system settings if the app is not of type "alarm or calendar".
        // You might need to check AlarmManager.canScheduleExactAlarms() via platform channel
        // and guide the user to settings.
        // For simplicity here, we just log. The `alarm` package might have its own handling.
    }
  }


  // Initialize flutter_local_notifications (if still needed for other purposes)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        // requestAlertPermission: true, // permission_handler is now preferred for notifications
        // requestBadgePermission: true,
        // requestSoundPermission: true,
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
            debugPrint('flutter_local_notifications payload: $payload');
          }
        },
    onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
  );
  // Create notification channel for flutter_local_notifications (if still needed)
  // await _createNotificationChannel(); 

  // Initialize the Alarm package
  try {
    // It's good practice to ensure permissions are handled *before* initializing a package that depends on them.
    await Alarm.init(); 
    print('Alarm package initialized successfully.');
  } catch (e) {
    print('Error initializing alarm package: $e');
  }

  print('Notification/Alarm services initialized');
}

// This function was for flutter_local_notifications. Keep if still used elsewhere.
// Future<void> _createNotificationChannel() async {
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'event_channel_id', // Channel ID
//     'Event Reminders', // Channel name
//     description: 'Notifications for upcoming events',
//     importance: Importance.max,
//     playSound: true,
//     showBadge: true,
//   );
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);
// }

Future<void> scheduleEventNotification(Event event) async {
  if (event.id == null) {
    print("Event ID is null, cannot schedule alarm for title: ${event.title}");
    return;
  }

  // Check the user's preference for this event
  if (!event.scheduleAlarm) {
    print('Alarm not scheduled for event "${event.title}" (ID: ${event.id}) as per user preference.');
    // Ensure any existing alarm for this event is cancelled if the preference was changed.
    await cancelEventNotification(event.id!); 
    return;
  }

  // Permission checks before scheduling (optional, as init should handle it, but good for robustness)
  if (Platform.isAndroid) {
    if (!await Permission.notification.isGranted) {
      print("Cannot schedule event notification: Notification permission not granted.");
      // Optionally, trigger request again or inform user
      // await Permission.notification.request(); 
      return;
    }
    // For SCHEDULE_EXACT_ALARM, it's more complex. 
    // The `alarm` package might have its own checks or rely on the initial grant.
    // If Alarm.set() fails, it could be due to this permission.
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
        icon: 'notification_icon', // Ensure this drawable exists in android/app/src/main/res/drawable
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

// // Pending Notifications function - COMMENTED OUT as it is for flutter_local_notifications
// // and not relevant for alarms from the 'alarm' package.
// Future<List<Map<String, dynamic>>> getPendingNotificationsWithDetails() async {
//   print(
//     'getPendingNotificationsWithDetails: This list is for flutter_local_notifications only.',
//   );
//   print('Alarms set by the \'alarm\' package are typically not listed here.');

//   final List<PendingNotificationRequest> pendingLocalNotifications =
//       await flutterLocalNotificationsPlugin.pendingNotificationRequests();
//   print(
//     'Pending flutter_local_notifications: ${pendingLocalNotifications.length}',
//   );

//   List<Map<String, dynamic>> detailedList = [];
//   for (var fln in pendingLocalNotifications) {
//     detailedList.add({
//       'id': fln.id,
//       'title': fln.title ?? 'N/A',
//       'body': fln.body ?? 'N/A',
//       'payload': fln.payload,
//       'type': 'Flutter Local Notification',
//     });
//   }
//   return detailedList;
// }

@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse notificationResponse) {
  // This callback is for flutter_local_notifications (if still used for other purposes)
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
  // TODO: Implement logic to iterate through your events from the database.
  // For each event, if event.endTimeAsDateTime.isBefore(DateTime.now()),
  // then call await Alarm.stop(event.id!) to cancel its alarm.
}
