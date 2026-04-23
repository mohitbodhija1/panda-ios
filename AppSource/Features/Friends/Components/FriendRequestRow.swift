//
//  FriendRequestRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Row for an *incoming* pending friendship request. Shows Accept / Decline
//  controls inline; the parent view supplies the async action handlers and
//  toggles `isBusy` while the network call is in flight.
//

import SwiftUI

struct FriendRequestRow: View {
    let friend: FriendRowItem
    let isBusy: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(friend.avatarTint.opacity(0.5))
                        .frame(width: 44, height: 44)
                    Text(String(friend.name.prefix(1)))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Wants to be your friend")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColor.cardHairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isBusy)

                Button(action: onAccept) {
                    Text(isBusy ? "…" : "Accept")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppColor.pandaBlue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .opacity(isBusy ? 0.6 : 1)
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
}
