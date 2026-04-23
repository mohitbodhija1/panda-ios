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

struct SettingsView: View {
    @State private var vm = SettingsViewModel()
    @State private var showSignOutConfirm: Bool = false
    @Environment(AuthSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

                    sectionHeader("Account")

                    signOutRow

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        .task { await vm.load() }
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
    }

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
