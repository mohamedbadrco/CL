import UIKit
import Flutter
import UserNotifications // Import this

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // If you want to customize how notifications are handled when the app is in the foreground
    // (e.g., to show an alert), you would uncomment the following lines and potentially
    // the userNotificationCenter(_:willPresent:withCompletionHandler:) method below.
    // For basic permission requests, this is not strictly necessary as
    // the flutter_local_notifications plugin handles the permission prompt.
    // if #available(iOS 10.0, *) {
    //   UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // --- Optional: Uncomment and customize if you want to explicitly handle foreground notifications ---
  // @available(iOS 10.0, *)
  // override func userNotificationCenter(
  //   _ center: UNUserNotificationCenter,
  //   willPresent notification: UNNotification,
  //   withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
  //   // Process the notification message here
  //
  //   // Show the notification alert, play sound, update badge etc.
  //   completionHandler([.alert, .sound, .badge])
  // }
  // ---
}