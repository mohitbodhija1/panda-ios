//
//  AuthTextField.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Rounded filled text field with a leading SF Symbol, used in auth forms.
//

import SwiftUI

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textPrimary)
                .keyboardType(keyboard)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColor.authFieldBg)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        AuthTextField(icon: "envelope.fill", placeholder: "Email address", text: .constant(""))
        AuthTextField(icon: "person.fill", placeholder: "Enter your full name", text: .constant("Ava"))
    }
    .padding()
}
