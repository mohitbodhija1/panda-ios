//
//  AuthSession.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Observable wrapper around Supabase Auth state. Inject once at the app root:
//
//      @State private var session = AuthSession()
//
//  And expose via `.environment(session)` so any view can react to sign-in /
//  sign-out without the @AppStorage hack the prototype used.
//

import Contacts
import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class AuthSession {
    private(set) var user: User?
    private(set) var isLoading: Bool = true

    var isAuthenticated: Bool { user != nil }
    var userId: UUID? { user?.id }

    init() {
        Task { await bootstrap() }
    }

    func bootstrap() async {
        defer { isLoading = false }
        do {
            let session = try await SupabaseProvider.auth.session
            user = session.user
        } catch {
            user = nil
        }

        Task {
            for await change in SupabaseProvider.auth.authStateChanges {
                user = change.session?.user
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await SupabaseProvider.auth.signIn(email: email, password: password)
        user = session.user
    }

    /// Native Sign in with Apple: exchange Apple's ID token for a Supabase session.
    /// When the ID token includes a `nonce` claim, `nonce` must match the raw
    /// value that was SHA256-hashed into `ASAuthorizationAppleIDRequest.nonce`.
    func signInWithApple(idToken: String, nonce: String? = nil) async throws {
        let session = try await SupabaseProvider.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: OpenIDConnectCredentials.Provider.apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        user = session.user
    }

    /// Apple only sends `fullName` on the first successful authorization. Persist
    /// it to `user_metadata` so `handle_new_user` / profile rows stay populated.
    func updateAppleProvidedFullName(_ fullName: PersonNameComponents?) async throws {
        guard let fullName else { return }
        let formatted = fullName.formatted(.name(style: .medium))
        let trimmed = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = try await SupabaseProvider.auth.update(
            user: UserAttributes(data: ["full_name": .string(trimmed)])
        )
    }

    func signUp(email: String, password: String, fullName: String) async throws {
        let response = try await SupabaseProvider.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )

        // If the project has email confirmation disabled, signUp returns a
        // session and the auth-state listener will populate `user`. If it
        // returns only a user (confirmation pending), try to sign in
        // immediately so the user lands inside the app without a round-trip
        // through their inbox. This succeeds the moment the dashboard flag
        // is off and surfaces a clean error otherwise.
        if let session = response.session {
            user = session.user
            return
        }

        let session = try await SupabaseProvider.auth.signIn(email: email, password: password)
        user = session.user
    }

    func signOut() async {
        try? await SupabaseProvider.auth.signOut()
        user = nil
    }

    /// Permanently deletes the signed-in user via GoTrue (`DELETE /auth/v1/user`).
    /// Requires a valid session JWT. Clears local auth state afterward.
    func deleteAccount() async throws {
        let session = try await SupabaseProvider.auth.session
        let base = SupabaseEnvironment.url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/auth/v1/user") else {
            throw AppError.validation("Invalid Supabase URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseEnvironment.anonKey, forHTTPHeaderField: "apikey")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown(NSError(domain: "AuthSession", code: -1))
        }
        guard (200...299).contains(http.statusCode) else {
            throw AppError.accountDeletionFailed(http.statusCode)
        }

        try? await SupabaseProvider.auth.signOut()
        user = nil
    }
}
