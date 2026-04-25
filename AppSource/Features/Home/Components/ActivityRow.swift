//
//  ActivityRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Reusable list row for Home's Recent Activity and the Activity tab.
//

import SwiftUI

struct ActivityRow: View {
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.avatarTint.opacity(0.35))
                    .frame(width: 42, height: 42)
                Image(systemName: deltaIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(activity.delta >= 0 ? AppColor.positive : AppColor.negative)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(activity.subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(trailingAmountText)
                    .font(AppFont.amountSmall)
                    .foregroundStyle(amountColor)
                Text(activity.dateLabel)
                    .font(.system(size: 11))
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

    private var deltaIcon: String {
        activity.delta >= 0 ? "arrow.down.left" : "arrow.up.right"
    }

    private var trailingAmountText: String {
        if activity.delta != 0 {
            return activity.delta.signedCurrencyString(code: activity.currency)
        }
        if activity.amount > 0 {
            return activity.amount.currencyString(code: activity.currency)
        }
        return "—"
    }

    private var amountColor: Color {
        if activity.delta > 0 { return AppColor.positive }
        if activity.delta < 0 { return AppColor.negative }
        return AppColor.textPrimary
    }
}
