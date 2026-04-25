//
//  SignInWithAppleAuthButton.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Wraps SwiftUI's `SignInWithAppleButton`, forwards the ID token to
//  `AuthSession.signInWithApple`, and persists the user's name on first sign-in
//  via `updateAppleProvidedFullName`. Uses a SHA256 nonce on the Apple request
//  and passes the raw nonce to Supabase when the token carries a nonce claim.
//

import AuthenticationServices
import CryptoKit
import SwiftUI

/// Holds the raw nonce between `onRequest` and `onCompletion` for the same
/// authorization attempt. `SignInWithAppleButton` does not give us a closure
/// that spans both phases with a shared stack frame.
private final class AppleSignInNonceBox: @unchecked Sendable {
    var rawNonce: String?
}

struct SignInWithAppleAuthButton: View {
    @Environment(AuthSession.self) private var session

    @Binding var isBusy: Bool
    @Binding var errorMessage: String?

    /// Use `.signIn` on the login screen and `.signUp` on the registration screen.
    private let buttonLabel: SignInWithAppleButton.Label

    @State private var nonceBox = AppleSignInNonceBox()

    init(
        isBusy: Binding<Bool>,
        errorMessage: Binding<String?>,
        buttonLabel: SignInWithAppleButton.Label = .signIn
    ) {
        _isBusy = isBusy
        _errorMessage = errorMessage
        self.buttonLabel = buttonLabel
    }

    var body: some View {
        SignInWithAppleButton(
            buttonLabel,
            onRequest: configureRequest,
            onCompletion: handleCompletion
        )
        .signInWithAppleButtonStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
        .disabled(isBusy)
        .opacity(isBusy ? 0.55 : 1)
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = nil
        let raw = Self.randomRawNonce()
        nonceBox.rawNonce = raw
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256Hex(of: raw)
    }

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        Task { @MainActor in
            defer { nonceBox.rawNonce = nil }

            switch result {
            case .failure(let error):
                errorMessage = AppError.wrap(error).errorDescription
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    errorMessage = "Could not read your Apple ID. Please try again."
                    return
                }
                guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                    errorMessage = "Missing identity token from Apple. Please try again."
                    return
                }

                isBusy = true
                defer { isBusy = false }

                do {
                    try await session.signInWithApple(idToken: idToken, nonce: nonceBox.rawNonce)
                    try await session.updateAppleProvidedFullName(credential.fullName)
                } catch {
                    errorMessage = AppError.wrap(error).errorDescription
                }
            }
        }
    }

    private static func randomRawNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(charset.randomElement()!)
        }
        return result
    }

    private static func sha256Hex(of input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    @Previewable @State var busy = false
    @Previewable @State var err: String?

    SignInWithAppleAuthButton(isBusy: $busy, errorMessage: $err)
        .padding()
        .environment(AuthSession())
}
