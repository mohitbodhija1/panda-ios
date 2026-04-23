//
//  OnboardingBackButton.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Small circular back chevron used as the top-left affordance on pages 2–4.
//

import SwiftUI

struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

#Preview {
    OnboardingBackButton(action: {})
}
