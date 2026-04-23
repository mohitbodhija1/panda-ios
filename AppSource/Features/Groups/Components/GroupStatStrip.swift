//
//  GroupStatStrip.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct GroupStatStrip: View {
    let totalExpenses: Decimal
    let youOwe: Decimal
    let youAreOwed: Decimal

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            column(title: "Total Expenses", amount: totalExpenses.currencyString, color: AppColor.textPrimary)
            divider
            column(title: "You Owe", amount: youOwe.currencyString, color: AppColor.negative)
            divider
            column(title: "You're Owed", amount: youAreOwed.currencyString, color: AppColor.positive)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.cardHairline)
            .frame(width: 1, height: 36)
    }

    private func column(title: String, amount: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)
            Text(amount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GroupStatStrip(totalExpenses: 480, youOwe: 120, youAreOwed: 0)
        .padding()
        .background(AppColor.bgTop)
}
