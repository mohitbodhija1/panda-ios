//
//  PushNotifications.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Implements the iOS half of the push pipeline:
//
//    1. `PushAppDelegate` adopts UIApplicationDelegate so we can capture
//       the APNs device token and forward it to `DeviceTokensService`.
//       It also adopts UNUserNotificationCenterDelegate so foreground
//       pushes display a banner + sound — useful for the "Send Test
//       Push" button in Settings.
//    2. `PushManager` is a small async façade for requesting permission
//       and triggering `registerForRemoteNotifications()`. Idempotent:
//       safe to call on every cold launch / sign-in.
//
//  The SwiftUI app installs the delegate via `@UIApplicationDelegateAdaptor`
//  in `PandaSplit___Bill_Splitter___Group_Expense_TrackerApp.swift`. The
//  permission request is fired from `RootView` once a Supabase session is
//  established so we never prompt anonymous users.
//

import UIKit
import UserNotifications

/// UIApplicationDelegate driving the APNs handshake. We deliberately keep
/// this class non-`@MainActor` because `UIApplicationDelegateAdaptor`
/// instantiates it from non-isolated context. The methods themselves are
/// invoked on the main thread by UIKit, and we hop into MainActor work
/// via `Task` whenever we touch our `@MainActor` services.
final class PushAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// APNs handed us a fresh device token. Forward it to Supabase so
    /// the `notify_on_*` Edge Functions and `send_test_push` can find
    /// this device.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { await DeviceTokensService.shared.register(token: deviceToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Soft failure: most often happens on the simulator (no APNs)
        // or with a missing aps-environment entitlement. The user sees
        // a status hint in Settings → Notifications.
        #if DEBUG
        print("[Push] registration failed: \(error.localizedDescription)")
        #endif
    }

    /// Show banner + sound while the app is foregrounded so test pushes
    /// are visible during development. Production behaviour is governed
    /// by the same flags so users always see incoming pushes.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

/// Façade around `UNUserNotificationCenter` that requests permission and
/// triggers APNs registration in a single idempotent step. Safe to call
/// every time the user signs in.
@MainActor
enum PushManager {
    /// Performs the full handshake:
    ///   * If permission is `.notDetermined`, prompts the user.
    ///   * If granted (`.authorized`/`.provisional`/`.ephemeral`), asks
    ///     UIKit to register for remote notifications. The token then
    ///     flows back through `PushAppDelegate.didRegisterForRemote…`
    ///     into `DeviceTokensService`.
    /// - Returns: the resulting authorization status so the UI can
    ///   render an accurate "Allow Notifications" / "Enabled" hint.
    @discardableResult
    static func ensurePermissionAndRegister() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()

        let initial = await center.notificationSettings().authorizationStatus
        if initial == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }

        let resolved = await center.notificationSettings().authorizationStatus
        if resolved == .authorized || resolved == .provisional || resolved == .ephemeral {
            UIApplication.shared.registerForRemoteNotifications()
        }
        return resolved
    }

    /// Read-only check for UI surfaces that just need to display state
    /// without re-prompting.
    static func currentStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}
