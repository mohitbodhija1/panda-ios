//
//  GroupHero.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct GroupHero: View {
    let groupId: UUID
    let avatarKey: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.chipBlue, AppColor.bgTop],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 164, height: 164)
                Image(GroupAvatar.imageName(for: avatarKey, groupId: groupId))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .clipShape(Circle())
            }
            .padding(.vertical, 8)
        }
        .frame(height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }
}

#Preview {
    GroupHero(groupId: UUID(), avatarKey: "group_avatar_3")
    .padding()
    .background(AppColor.bgTop)
}
