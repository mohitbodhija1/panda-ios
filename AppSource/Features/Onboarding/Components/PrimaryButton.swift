//
//  PrimaryButton.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Full-width filled pill button used for the onboarding CTAs.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppColor.pandaBlue)
                )
                .shadow(color: AppColor.pandaBlue.opacity(0.25), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

#Preview {
    PrimaryButton(title: "Get Started", action: {})
        .padding()
}
