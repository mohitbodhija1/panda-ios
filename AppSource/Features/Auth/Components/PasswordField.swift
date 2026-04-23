//
//  PasswordField.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Secure-entry field with an eye toggle that mirrors AuthTextField styling.
//

import SwiftUI

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType? = .password

    @State private var isRevealed: Bool = false

    private var prompt: Text {
        Text(placeholder)
            .font(AppFont.bodyRegular)
            .foregroundStyle(Color.black)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 20)

            Group {
                if isRevealed {
                    TextField("", text: $text, prompt: prompt)
                } else {
                    SecureField("", text: $text, prompt: prompt)
                }
            }
            .font(AppFont.bodyRegular)
            .foregroundStyle(AppColor.textPrimary)
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
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
    PasswordField(placeholder: "Password", text: .constant(""))
        .padding()
}
