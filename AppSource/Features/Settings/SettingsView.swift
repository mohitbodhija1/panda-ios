//
//  SettingsView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Minimal preferences sheet. Starts with the default currency dropdown and
//  is designed to hold future user-level preferences. Also exposes a
//  destructive Sign Out action; RootView observes AuthSession.isAuthenticated
//  and routes back to LoginView automatically.
//

import SwiftUI
import UserNotifications

/// Routes pushed from Settings. Kept on a single enum so the navigation stack
/// stays serialisable and previews don't have to construct destinations.
enum SettingsRoute: Hashable {
    case account
    case privacyPolicy
    case termsOfService
}

struct SettingsView: View {
    /// Email address that the "Contact Us for help" row opens in the user's
    /// default mail client. Centralised here so privacy / terms / mailto stay
    /// in sync.
    static let supportEmail = "mbodhija80@gmail.com"

    @State private var vm = SettingsViewModel()
    @State private var showSignOutConfirm: Bool = false
    /// Cached APNs authorization status so the row label stays accurate
    /// without having to re-prompt every render.
    @State private var pushStatus: UNAuthorizationStatus = .notDetermined
    // Test-push UI hidden once we verified the pipeline end-to-end.
    // Re-enable by uncommenting these states + the button in
    // `notificationsCard` and the inline status `Text` below the card.
    // @State private var isSendingTestPush: Bool = false
    // @State private var testPushMessage: String?
    // @State private var testPushIsError: Bool = false
    // Delete-account flow is intentionally hidden until the server-side
    // cascade + audit trail are finalised. Keep the state and dialog wiring
    // so re-enabling is a one-line UI change.
    // @State private var showDeleteAccountConfirm: Bool = false
    // @State private var isDeletingAccount: Bool = false
    // @State private var deleteAccountError: String?
    @State private var path: [SettingsRoute] = []
    @Environment(AuthSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppColor.bgTop.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        navBar

                        Text("Pick defaults that apply to every new group\nand expense you create.")
                            .font(AppFont.bodyRegular)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)

                        TintedFormCard {
                            CurrencyPickerRow(
                                icon: "dollarsign.circle",
                                tint: AppColor.avatarPink,
                                title: "Default Currency",
                                code: Binding(
                                    get: { vm.defaultCurrency },
                                    set: { newValue in
                                        Task { await vm.setDefaultCurrency(newValue) }
                                    }
                                )
                            )
                        }

                        if vm.isSaving {
                            Text("Saving…")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        if let message = vm.errorMessage {
                            Text(message)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.negative)
                                .multilineTextAlignment(.center)
                        }

                        sectionHeader("Notifications")

                        notificationsCard

                        // Inline test-push result hidden alongside the
                        // "Send Test Push" button. Re-enable along with
                        // the test-push state vars and button below.
                        // if let testPushMessage {
                        //     Text(testPushMessage)
                        //         .font(AppFont.caption)
                        //         .foregroundStyle(testPushIsError ? AppColor.negative : AppColor.textSecondary)
                        //         .multilineTextAlignment(.center)
                        // }

                        sectionHeader("Help & Legal")

                        helpAndLegalCard

                        sectionHeader("Account")

                        accountCard

                        // Delete-account button hidden until server-side
                        // cascade + audit pipeline are signed off.
                        // deleteAccountRow
                        // if let deleteAccountError {
                        //     Text(deleteAccountError)
                        //         .font(AppFont.caption)
                        //         .foregroundStyle(AppColor.negative)
                        //         .multilineTextAlignment(.center)
                        // }

                        signOutRow

                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .account:          AccountView()
                case .privacyPolicy:    PrivacyPolicyView()
                case .termsOfService:   TermsOfServiceView()
                }
            }
        }
        .task { await vm.load() }
        .task {
            // Keep the permission row label honest each time Settings opens.
            pushStatus = await PushManager.currentStatus()
        }
        .confirmationDialog(
            "Sign out of PandaSplit?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await session.signOut()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your groups and expenses.")
        }
        // Delete-account confirmation hidden alongside the trigger row.
        // .confirmationDialog(
        //     "Delete your PandaSplit account?",
        //     isPresented: $showDeleteAccountConfirm,
        //     titleVisibility: .visible
        // ) {
        //     Button("Delete Account", role: .destructive) {
        //         Task {
        //             isDeletingAccount = true
        //             deleteAccountError = nil
        //             defer { isDeletingAccount = false }
        //             do {
        //                 try await session.deleteAccount()
        //                 dismiss()
        //             } catch {
        //                 deleteAccountError = AppError.wrap(error).errorDescription
        //             }
        //         }
        //     }
        //     Button("Cancel", role: .cancel) {}
        // } message: {
        //     Text("This permanently removes your account. You cannot undo this.")
        // }
    }

    private var accountCard: some View {
        TintedFormCard {
            NavigationLink(value: SettingsRoute.account) {
                TintedFormRow(
                    icon: "person.crop.circle.fill",
                    tint: AppColor.chipBlue,
                    title: "Edit Profile",
                    value: "Update your name and photo",
                    isPlaceholder: true,
                    trailingChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Card that surfaces the APNs permission state. The "Send Test
    /// Push" affordance is intentionally commented out now that the
    /// pipeline is verified end-to-end — uncomment to re-enable for
    /// future debugging.
    private var notificationsCard: some View {
        TintedFormCard {
            Button { Task { await togglePushPermission() } } label: {
                TintedFormRow(
                    icon: pushStatus == .authorized ? "bell.fill" : "bell.slash.fill",
                    tint: AppColor.chipBlue,
                    title: pushPermissionTitle,
                    value: pushPermissionSubtitle,
                    isPlaceholder: pushStatus != .authorized,
                    trailingChevron: pushStatus != .authorized && pushStatus != .provisional
                )
            }
            .buttonStyle(.plain)

            // Test push button hidden once verified end-to-end.
            // Re-enable by uncommenting this block + the related state
            // vars and inline result Text in `body`.
            // Button { Task { await sendTestPush() } } label: {
            //     TintedFormRow(
            //         icon: "paperplane.fill",
            //         tint: AppColor.avatarTintC,
            //         title: isSendingTestPush ? "Sending Test Push…" : "Send Test Push",
            //         value: "Delivers a sample APNs alert to this device",
            //         isPlaceholder: true,
            //         trailingChevron: false
            //     )
            // }
            // .buttonStyle(.plain)
            // .disabled(isSendingTestPush || pushStatus != .authorized)
        }
    }

    private var pushPermissionTitle: String {
        switch pushStatus {
        case .authorized:    return "Notifications Enabled"
        case .provisional:   return "Quiet Notifications"
        case .ephemeral:     return "Notifications Active"
        case .denied:        return "Notifications Blocked"
        case .notDetermined: return "Allow Notifications"
        @unknown default:    return "Notifications"
        }
    }

    private var pushPermissionSubtitle: String {
        switch pushStatus {
        case .authorized:    return "All set — pushes will arrive on this device"
        case .provisional:   return "Delivered silently to Notification Center"
        case .ephemeral:     return "Active for this App Clip session"
        case .denied:        return "Tap to open iOS Settings and re-enable"
        case .notDetermined: return "Tap to grant permission"
        @unknown default:    return ""
        }
    }

    /// Two-step interaction: if iOS hasn't been asked yet, prompt; if
    /// the user previously denied, deep-link them into iOS Settings so
    /// they can flip the switch back on.
    private func togglePushPermission() async {
        if pushStatus == .denied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
            return
        }
        pushStatus = await PushManager.ensurePermissionAndRegister()
    }

    // Hidden alongside the test-push button. The hook stays in the
    // service layer (`NotificationsService.sendTestPush`) so re-enabling
    // is a copy-paste away.
    // private func sendTestPush() async {
    //     guard !isSendingTestPush else { return }
    //     isSendingTestPush = true
    //     testPushMessage = nil
    //     testPushIsError = false
    //     defer { isSendingTestPush = false }
    //     do {
    //         let result = try await NotificationsService.shared.sendTestPush()
    //         if result.devices == 0 {
    //             testPushIsError = true
    //             testPushMessage = "No registered device tokens. Make sure notifications are enabled and run on a real device (the simulator can't receive APNs)."
    //         } else {
    //             testPushMessage = "Sent to \(result.devices) device(s) — delivered: \(result.pushed), failed: \(result.failed)."
    //             testPushIsError = result.failed > 0
    //         }
    //     } catch {
    //         testPushIsError = true
    //         testPushMessage = AppError.wrap(error).errorDescription
    //     }
    // }

    private var helpAndLegalCard: some View {
        TintedFormCard {
            NavigationLink(value: SettingsRoute.privacyPolicy) {
                TintedFormRow(
                    icon: "hand.raised.fill",
                    tint: AppColor.chipBlue,
                    title: "Privacy Policy",
                    value: "How we handle your data",
                    isPlaceholder: true,
                    trailingChevron: true
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: SettingsRoute.termsOfService) {
                TintedFormRow(
                    icon: "doc.text.fill",
                    tint: AppColor.avatarTintE,
                    title: "Terms & Conditions",
                    value: "Rules for using PandaSplit",
                    isPlaceholder: true,
                    trailingChevron: true
                )
            }
            .buttonStyle(.plain)

            Button { contactSupport() } label: {
                TintedFormRow(
                    icon: "envelope.fill",
                    tint: AppColor.avatarTintD,
                    title: "Contact Us for Help",
                    value: Self.supportEmail,
                    isPlaceholder: true,
                    trailingChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func contactSupport() {
        let subject = "PandaSplit Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(Self.supportEmail)?subject=\(subject)") else { return }
        openURL(url)
    }

    // Hidden until delete-account flow is fully verified end-to-end.
    // private var deleteAccountRow: some View {
    //     Button {
    //         showDeleteAccountConfirm = true
    //     } label: {
    //         HStack(spacing: 12) {
    //             Image(systemName: "trash.fill")
    //                 .font(.system(size: 15, weight: .semibold))
    //                 .foregroundStyle(AppColor.negative)
    //                 .frame(width: 32, height: 32)
    //                 .background(Circle().fill(AppColor.negative.opacity(0.12)))
    //             Text(isDeletingAccount ? "Deleting…" : "Delete Account")
    //                 .font(AppFont.rowTitle)
    //                 .foregroundStyle(AppColor.negative)
    //             Spacer()
    //         }
    //         .padding(.horizontal, 14)
    //         .padding(.vertical, 12)
    //         .background(
    //             RoundedRectangle(cornerRadius: 16, style: .continuous)
    //                 .fill(Color.white)
    //         )
    //         .overlay(
    //             RoundedRectangle(cornerRadius: 16, style: .continuous)
    //                 .stroke(AppColor.cardHairline, lineWidth: 1)
    //         )
    //     }
    //     .buttonStyle(.plain)
    //     .disabled(isDeletingAccount)
    // }

    private var signOutRow: some View {
        Button { showSignOutConfirm = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.negative)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColor.negative.opacity(0.12)))
                Text("Sign Out")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.negative)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColor.cardHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppColor.cardHairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }
}
