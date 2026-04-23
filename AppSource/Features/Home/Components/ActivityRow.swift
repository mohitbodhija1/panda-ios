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
                Text(activity.delta.signedCurrencyString)
                    .font(AppFont.amountSmall)
                    .foregroundStyle(activity.delta >= 0 ? AppColor.positive : AppColor.negative)
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
}
