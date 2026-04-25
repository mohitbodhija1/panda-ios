//
//  PendingInviteRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Renders a friend invite that has not yet been claimed by a real account
//  (e.g. invited by email/phone and the recipient hasn't signed up). Supports
//  withdrawing the invite via the trailing "Cancel" button.
//

import SwiftUI

struct PendingInviteRow: View {
    let invite: PendingInviteRowItem
    var isBusy: Bool = false
    var onCancel: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(invite.avatarTint.opacity(0.5))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(invite.label)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("Waiting on signup")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            if let onCancel {
                Button {
                    onCancel()
                } label: {
                    Text(isBusy ? "…" : "Cancel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.negative)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColor.negative.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            } else {
                Text("Pending")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColor.chipBlue))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }

    private var icon: String {
        switch invite.channel {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        }
    }
}
