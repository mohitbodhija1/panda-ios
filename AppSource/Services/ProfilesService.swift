//
//  ProfilesService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

@MainActor
final class ProfilesService {
    static let shared = ProfilesService()

    private var db: PostgrestClient { SupabaseProvider.db }

    func me() async throws -> ProfileDTO {
        guard let userId = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }
        return try await fetch(id: userId)
    }

    func fetch(id: UUID) async throws -> ProfileDTO {
        try await db.from("profiles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func updateMe(fullName: String?, username: String?, avatarUrl: String?) async throws -> ProfileDTO {
        guard let userId = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }

        struct Patch: Encodable {
            let full_name: String?
            let username: String?
            let avatar_url: String?
        }

        return try await db.from("profiles")
            .update(Patch(full_name: fullName, username: username, avatar_url: avatarUrl))
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
    }

    /// Persists the caller's preferred currency (3-letter ISO code) on their
    /// profile row. Upper-cases the input so we store the canonical form.
    @discardableResult
    func updateDefaultCurrency(_ code: String) async throws -> ProfileDTO {
        guard let userId = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }

        struct Patch: Encodable { let default_currency: String }

        return try await db.from("profiles")
            .update(Patch(default_currency: code.uppercased()))
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
    }
}
