//
//  GroupSettingsSheet.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Dev sheet exposed through the Group Detail gear icon. Used to sign out
//  or reset onboarding so we can exercise the full flow without real auth.
//

import SwiftUI

struct GroupSettingsSheet: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(AuthSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppColor.cardHairline)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Group Settings")
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, 4)

            VStack(spacing: 10) {
                settingsRow(icon: "person.crop.circle.badge.plus", title: "Invite Members", tint: AppColor.pandaBlue) {}
                settingsRow(icon: "pencil", title: "Edit Group", tint: AppColor.textPrimary) {}
                settingsRow(icon: "bell.slash.fill", title: "Mute Notifications", tint: AppColor.textPrimary) {}
            }

            Divider().padding(.vertical, 4)

            Text("Developer")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign out", tint: AppColor.negative) {
                    Task {
                        await session.signOut()
                        dismiss()
                    }
                }
                settingsRow(icon: "arrow.counterclockwise", title: "Reset onboarding", tint: AppColor.negative) {
                    Task {
                        await session.signOut()
                        hasCompletedOnboarding = false
                        dismiss()
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(AppColor.bgTop.ignoresSafeArea())
    }

    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(tint.opacity(0.12)))
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
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
}

#Preview {
    GroupSettingsSheet()
        .environment(AuthSession())
}
