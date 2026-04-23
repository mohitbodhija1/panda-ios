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
        user = response.user
    }

    func signOut() async {
        try? await SupabaseProvider.auth.signOut()
        user = nil
    }
}
