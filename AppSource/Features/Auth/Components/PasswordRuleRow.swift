//
//  PasswordRuleRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Live-updating checklist row used under the sign-up password field.
//

import SwiftUI

struct PasswordRuleRow: View {
    let title: String
    let isSatisfied: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSatisfied ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSatisfied ? AppColor.positive : AppColor.dotInactive)

            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(isSatisfied ? AppColor.textPrimary : AppColor.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 6) {
        PasswordRuleRow(title: "At least 8 characters", isSatisfied: true)
        PasswordRuleRow(title: "Includes a number", isSatisfied: false)
        PasswordRuleRow(title: "Includes an uppercase letter", isSatisfied: false)
    }
    .padding()
}
