//
//  AppleSignInButton.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  White-background "Continue with Apple" styled button used on login.
//  Illustrative only; does not start a real ASAuthorization flow.
//

import SwiftUI

struct AppleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .medium))
                Text("Continue with Apple")
                    .font(AppFont.button)
            }
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppColor.cardHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppleSignInButton(action: {})
        .padding()
}
