//
//  PaywallFeatureRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.pandaBlue)
                .frame(width: 38, height: 38)
                .background(Circle().fill(AppColor.chipBlue))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    PaywallFeatureRow(
        icon: "infinity.circle.fill",
        title: "Unlimited Groups",
        subtitle: "Create as many groups as you need"
    )
    .padding()
}
