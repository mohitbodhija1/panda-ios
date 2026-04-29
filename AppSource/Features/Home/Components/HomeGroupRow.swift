//
//  HomeGroupRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Compact group row shared between the Home screen and the Groups list tab.
//

import SwiftUI

struct HomeGroupRow: View {
    let group: GroupRowItem

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("\(group.memberCount) members")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(balanceLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.textSecondary)
                Text(amountText)
                    .font(AppFont.amountSmall)
                    .foregroundStyle(amountColor)
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

    private var thumbnail: some View {
        ZStack {
            Circle()
                .fill(AppColor.chipBlue)
                .frame(width: 50, height: 50)
            Image(GroupAvatar.imageName(for: group.avatarKey, groupId: group.id))
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
        }
    }

    private var balanceLabel: String {
        if group.yourBalance > 0 { return "You're owed" }
        if group.yourBalance < 0 { return "You owe" }
        return "Settled"
    }

    private var amountText: String {
        if group.yourBalance == 0 { return Decimal(0).currencyString(code: group.currency) }
        let magnitude = (group.yourBalance < 0 ? -group.yourBalance : group.yourBalance)
            .currencyString(code: group.currency)
        return group.yourBalance < 0 ? "-\(magnitude)" : "+\(magnitude)"
    }

    private var amountColor: Color {
        if group.yourBalance > 0 { return AppColor.positive }
        if group.yourBalance < 0 { return AppColor.negative }
        return AppColor.textSecondary
    }
}
