//
//  SignUpView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Sign-up screen with a live-validated password checklist.
//

import SwiftUI

struct SignUpView: View {
    @Environment(AuthSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    private var hasMinimumLength: Bool { password.count >= 8 }
    private var hasNumber: Bool { password.contains(where: { $0.isNumber }) }
    private var hasUppercase: Bool { password.contains(where: { $0.isUppercase }) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            OnboardingBackground()

            ScrollView {
                VStack(spacing: 0) {
                    Text("Create your account")
                        .font(AppFont.pageTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.top, 56)

                    Text("Join Panda and start splitting\nexpenses effortlessly.")
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)

                    Image("pandas_highfive")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 170)
                        .padding(.top, 8)

                    VStack(spacing: 14) {
                        labeledField(label: "Full Name") {
                            AuthTextField(
                                icon: "person.fill",
                                placeholder: "Enter your full name",
                                text: $fullName,
                                textContentType: .name,
                                autocapitalization: .words
                            )
                        }
                        labeledField(label: "Email Address") {
                            AuthTextField(
                                icon: "envelope.fill",
                                placeholder: "Enter your email",
                                text: $email,
                                keyboard: .emailAddress,
                                textContentType: .emailAddress
                            )
                        }
                        labeledField(label: "Password") {
                            PasswordField(
                                placeholder: "Create a password",
                                text: $password,
                                textContentType: .newPassword
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                PasswordRuleRow(title: "At least 8 characters", isSatisfied: hasMinimumLength)
                                PasswordRuleRow(title: "Includes a number", isSatisfied: hasNumber)
                                PasswordRuleRow(title: "Includes an uppercase letter", isSatisfied: hasUppercase)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.top, 14)

                    PrimaryButton(title: isSubmitting ? "Creating account..." : "Sign Up") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || !canSubmit)
                    .padding(.top, 22)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .padding(.top, 8)
                    }

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(AppColor.textSecondary)
                        Button("Log in") { dismiss() }
                            .foregroundStyle(AppColor.pandaBlue)
                            .fontWeight(.semibold)
                    }
                    .font(AppFont.caption)
                    .padding(.top, 18)

                    PageDots(count: 5, selectedIndex: 1)
                        .padding(.top, 20)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            OnboardingBackButton { dismiss() }
                .padding(.top, 8)
                .padding(.leading, 8)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var canSubmit: Bool {
        !fullName.isEmpty && !email.isEmpty && hasMinimumLength && hasNumber && hasUppercase
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await session.signUp(email: email, password: password, fullName: fullName)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    @ViewBuilder
    private func labeledField<Field: View>(
        label: String,
        @ViewBuilder _ field: () -> Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.textPrimary)
            field()
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environment(AuthSession())
}
