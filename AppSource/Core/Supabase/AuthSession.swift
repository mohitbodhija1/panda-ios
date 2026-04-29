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
import Functions
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

    /// Permanently deletes the signed-in user via the `delete_account` Edge Function
    /// (DB anonymization + `auth.admin.deleteUser`). Requires a valid session JWT.
    /// Clears local auth state afterward.
    func deleteAccount() async throws {
        let session: Session
        do {
            session = try await SupabaseProvider.auth.session
        } catch {
            throw AppError.notAuthenticated
        }

        do {
            try await SupabaseProvider.functions.invoke(
                "delete_account",
                options: FunctionInvokeOptions(
                    method: .post,
                    headers: [
                        "Authorization": "Bearer \(session.accessToken)",
                        "apikey": SupabaseEnvironment.anonKey,
                    ]
                )
            )
        } catch let fnError as FunctionsError {
            throw Self.mapDeleteAccountError(fnError)
        } catch {
            throw AppError.server(
                "Could not delete your account: \(error.localizedDescription)"
            )
        }

        try? await SupabaseProvider.auth.signOut()
        user = nil
    }

    /// Maps Edge Function failures to actionable copy (404 usually means the function was never deployed).
    private static func mapDeleteAccountError(_ error: FunctionsError) -> AppError {
        switch error {
        case .relayError:
            return .server(
                "Could not reach account deletion. Check your connection and try again."
            )
        case .httpError(let code, let data):
            let detail = edgeFunctionJSONMessage(from: data)
            switch code {
            case 401:
                return .notAuthenticated
            case 404:
                return .server(
                    "Account deletion isn’t available on this backend yet. Deploy the delete_account Edge Function and apply migrations (supabase functions deploy delete_account; supabase db push)."
                )
            case 500...599:
                let suffix = detail.map { " \($0)" } ?? ""
                return .server(
                    "The server couldn’t finish deleting your account.\(suffix) Try again or contact support."
                )
            default:
                let suffix = detail.map { ": \($0)" } ?? ""
                return .server(
                    "Could not delete your account (HTTP \(code))\(suffix). Try again or contact support."
                )
            }
        }
    }

    private static func edgeFunctionJSONMessage(from data: Data) -> String? {
        struct Body: Decodable {
            let error: String?
            let message: String?
        }
        guard !data.isEmpty else { return nil }
        if let body = try? JSONDecoder().decode(Body.self, from: data) {
            let combined = body.error ?? body.message
            let t = combined?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return t.isEmpty ? nil : t
        }
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : raw
    }
}
