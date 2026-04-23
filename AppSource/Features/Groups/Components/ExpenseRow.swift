//
//  ExpenseRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct ExpenseRow: View {
    let expense: ExpenseRowItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.chipBlue)
                    .frame(width: 44, height: 44)
                Text(expense.emoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(expense.subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Text(expense.amount.currencyString(code: expense.currency))
                .font(AppFont.amount)
                .foregroundStyle(AppColor.textPrimary)
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
