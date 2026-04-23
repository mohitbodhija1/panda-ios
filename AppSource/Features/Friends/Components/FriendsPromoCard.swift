//
//  FriendsPromoCard.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Top card on the Friends tab that markets the add-friend CTA.
//

import SwiftUI

struct FriendsPromoCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image("panda_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Split expenses easily")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Invite your friends and start tracking")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            NavigationLink(value: FriendsRoute.addFriend) {
                Circle()
                    .fill(AppColor.pandaBlue)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }
}

#Preview {
    FriendsPromoCard().padding().background(AppColor.bgTop)
}
