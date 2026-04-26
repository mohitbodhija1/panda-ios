//
//  PandaSplit___Bill_Splitter___Group_Expense_TrackerApp.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Created by Mohit Bodhija on 22/04/26.
//

import SwiftUI

@main
struct PandaSplit___Bill_Splitter___Group_Expense_TrackerApp: App {
    /// Keeps the APNs token handshake alive for the entire app lifetime.
    /// The delegate forwards device tokens to `DeviceTokensService` so
    /// the `notify_on_*` and `send_test_push` Edge Functions can target
    /// this device.
    @UIApplicationDelegateAdaptor(PushAppDelegate.self) private var pushDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
