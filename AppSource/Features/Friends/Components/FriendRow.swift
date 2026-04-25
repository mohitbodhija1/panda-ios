//
//  FriendRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct FriendRow: View {
    let friend: FriendRowItem

    var body: some View {
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
                Text(subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                if friend.isPending {
                    pendingPill
                } else {
                    Text(amountText)
                        .font(AppFont.amountSmall)
                        .foregroundStyle(amountColor)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
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

    private var subtitle: String {
        if friend.isPending { return "Invite pending · tap to add expense" }
        if friend.balance > 0 { return "owes you" }
        if friend.balance < 0 { return "you owe" }
        return "all settled"
    }

    private var pendingPill: some View {
        Text("Pending")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColor.pandaBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(AppColor.chipBlue))
    }

    private var amountText: String {
        if friend.balance == 0 { return Decimal(0).currencyString(code: friend.currency) }
        let magnitude = (friend.balance < 0 ? -friend.balance : friend.balance)
            .currencyString(code: friend.currency)
        return friend.balance < 0 ? "-\(magnitude)" : "+\(magnitude)"
    }

    private var amountColor: Color {
        if friend.balance > 0 { return AppColor.positive }
        if friend.balance < 0 { return AppColor.negative }
        return AppColor.textSecondary
    }
}
