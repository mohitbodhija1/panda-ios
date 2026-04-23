//
//  HomeHeroCard.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Greeting card on the Home screen that anchors the BalanceSummary chip.
//

import SwiftUI

struct HomeHeroCard: View {
    let firstName: String
    let youOwe: Decimal
    let youAreOwed: Decimal
    let owedGroups: Int
    let owedFrom: Int
    let currencyCode: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hi, \(firstName) 👋")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Here's what's happening\nwith your expenses.")
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    Image("panda_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Image(systemName: CurrencyGlyph.sfSymbolName(for: currencyCode))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(AppColor.pandaBlue)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 28)

            BalanceSummary(
                youOwe: youOwe,
                youAreOwed: youAreOwed,
                owedGroups: owedGroups,
                owedFrom: owedFrom,
                currencyCode: currencyCode
            )
            .padding(.horizontal, 16)
            .offset(y: 30)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: AppColor.textPrimary.opacity(0.05), radius: 18, x: 0, y: 6)
        )
        .padding(.bottom, 34)
    }
}

#Preview {
    HomeHeroCard(
        firstName: "Ava",
        youOwe: 156.50,
        youAreOwed: 89.20,
        owedGroups: 3,
        owedFrom: 2,
        currencyCode: "USD"
    )
    .padding()
    .background(AppColor.bgTop)
}
