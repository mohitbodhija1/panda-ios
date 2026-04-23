//
//  PricingCard.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct PricingCard: View {
    let title: String
    let price: String
    let caption: String
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.textSecondary)
                    Text(price)
                        .font(AppFont.priceBig)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(caption)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? AppColor.pandaBlue : AppColor.cardHairline, lineWidth: isSelected ? 2 : 1)
                )

                if isBestValue {
                    Text("Best Value")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(AppColor.goldAccent)
                        )
                        .offset(x: -10, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        PricingCard(title: "Monthly", price: "$4.99", caption: "per month", isSelected: false, isBestValue: false, action: {})
        PricingCard(title: "Yearly", price: "$39.99", caption: "per year", isSelected: true, isBestValue: true, action: {})
    }
    .padding()
}
