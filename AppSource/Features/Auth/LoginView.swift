//
//  LoginView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Pixel-perfect login screen wired to Supabase Auth via AuthSession.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthSession.self) private var session

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting: Bool = false
    @State private var isAppleSigningIn: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            OnboardingBackground()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    Image("panda_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: AppColor.pandaBlue.opacity(0.18), radius: 20, x: 0, y: 10)
                        .padding(.top, 8)

                    Text("Welcome back!")
                        .font(AppFont.pageTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.top, 20)

                    Text("Log in to continue splitting\nexpenses with ease.")
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)

                    VStack(spacing: 12) {
                        AuthTextField(
                            icon: "envelope.fill",
                            placeholder: "Email address",
                            text: $email,
                            keyboard: .emailAddress,
                            textContentType: .emailAddress
                        )
                        PasswordField(placeholder: "Password", text: $password)
                    }
                    .padding(.top, 24)

                    HStack {
                        Button("Forgot password?") { /* illustrative */ }
                            .font(AppFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.pandaBlue)
                        Spacer()
                    }
                    .padding(.top, 12)

                    PrimaryButton(title: isSubmitting ? "Logging in..." : "Log In") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || isAppleSigningIn || email.isEmpty || password.isEmpty)
                    .padding(.top, 18)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .padding(.top, 8)
                    }

                    orDivider
                        .padding(.vertical, 18)

                    SignInWithAppleAuthButton(isBusy: $isAppleSigningIn, errorMessage: $errorMessage)

                    signUpPrompt
                        .padding(.top, 22)

                    PageDots(count: 5, selectedIndex: 0)
                        .padding(.top, 20)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboardForForms()
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppColor.cardHairline)
                .frame(height: 1)
            Text("or")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Rectangle()
                .fill(AppColor.cardHairline)
                .frame(height: 1)
        }
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await session.signIn(email: email, password: password)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private var signUpPrompt: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(AppColor.textSecondary)
            NavigationLink(value: AuthRoute.signUp) {
                Text("Sign up")
                    .foregroundStyle(AppColor.pandaBlue)
                    .fontWeight(.semibold)
            }
        }
        .font(AppFont.caption)
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(AuthSession())
}
