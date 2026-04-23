//
//  BalanceSummary.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Gradient card that surfaces the user's net position on the Home hero.
//

import SwiftUI

struct BalanceSummary: View {
    let youOwe: Decimal
    let youAreOwed: Decimal
    let owedGroups: Int
    let owedFrom: Int
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            column(
                label: "You owe",
                amount: youOwe.currencyString(code: currencyCode),
                subtitle: "across \(owedGroups) groups"
            )

            Divider()
                .frame(width: 1, height: 48)
                .overlay(Color.white.opacity(0.25))

            column(
                label: "You are owed",
                amount: youAreOwed.currencyString(code: currencyCode),
                subtitle: "from \(owedFrom) friends"
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.balanceNavy, AppColor.balanceBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(alignment: .bottom) {
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.pandaBlue)
                )
                .offset(y: 14)
        }
        .shadow(color: AppColor.balanceNavy.opacity(0.25), radius: 18, x: 0, y: 10)
    }

    private func column(label: String, amount: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.75))
            Text(amount)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BalanceSummary(youOwe: 156.50, youAreOwed: 89.20, owedGroups: 3, owedFrom: 2, currencyCode: "USD")
        .padding()
        .background(AppColor.bgTop)
}
