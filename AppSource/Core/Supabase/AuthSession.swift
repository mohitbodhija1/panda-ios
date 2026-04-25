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
}
