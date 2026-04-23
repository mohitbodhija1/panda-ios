//
//  InviteFriendsCard.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct InviteFriendsCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColor.chipBlue)
                    .frame(width: 44, height: 44)
                Image(systemName: "link")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Invite friends")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Share your link and split faster")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Text("Share")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.pandaBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppColor.chipBlue))
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
    InviteFriendsCard().padding().background(AppColor.bgTop)
}
