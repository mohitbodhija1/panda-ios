//
//  OptionRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Card-styled informational row with leading SF Symbol, title, subtitle
//  and a trailing affordance. Rows are illustrative during onboarding.
//

import SwiftUI

struct OptionRow: View {
    enum Trailing {
        case chevron
        case plus
    }

    let icon: String
    let title: String
    let subtitle: String
    var trailing: Trailing = .chevron

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.iconTintBg)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer(minLength: 8)

            trailingView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
        case .plus:
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColor.pandaBlue)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        OptionRow(
            icon: "person.crop.circle.badge.plus",
            title: "Add Friends",
            subtitle: "Connect your contacts"
        )
        OptionRow(
            icon: "person.3.fill",
            title: "Create Group",
            subtitle: "Start a new group",
            trailing: .plus
        )
    }
    .padding()
    .background(OnboardingBackground())
}
