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
    private var storage: SupabaseStorageClient { SupabaseProvider.storage }

    /// Storage bucket that backs profile avatars (see migration
    /// `20260422121100_storage.sql`). Public-read, owner-write so we can
    /// store the resulting public URL straight on `profiles.avatar_url`.
    private static let avatarsBucket = "avatars"

    func me() async throws -> ProfileDTO {
        guard let userId = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }
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

    /// Patches the caller's profile row. Any argument left `nil` is *not*
    /// sent to the server — so callers can update one field at a time
    /// without clobbering the others. Use a dedicated helper if you ever
    /// need to explicitly clear a column to NULL.
    func updateMe(fullName: String? = nil, username: String? = nil, avatarUrl: String? = nil) async throws -> ProfileDTO {
        guard let userId = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }

        struct Patch: Encodable {
            let fullName: String?
            let username: String?
            let avatarUrl: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case username
                case avatarUrl = "avatar_url"
            }

            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                if let fullName { try c.encode(fullName, forKey: .fullName) }
                if let username { try c.encode(username, forKey: .username) }
                if let avatarUrl { try c.encode(avatarUrl, forKey: .avatarUrl) }
            }
        }

        return try await db.from("profiles")
            .update(Patch(fullName: fullName, username: username, avatarUrl: avatarUrl))
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
    }

    /// Uploads the given image bytes to the public `avatars` bucket under
    /// the caller's user folder and returns the resulting public URL. The
    /// caller is responsible for persisting the URL onto their profile row
    /// (typically via `updateMe`).
    ///
    /// We always upload to the same path (`<user_id>/avatar.jpg`) and rely
    /// on `upsert: true` so storage stays bounded — old avatars are simply
    /// overwritten. A timestamp query string is appended on read to bust
    /// any CDN/cache for the new bytes.
    func uploadAvatar(data: Data, contentType: String = "image/jpeg") async throws -> String {
        guard let userId = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }

        let ext = contentType == "image/png" ? "png" : "jpg"
        // Storage RLS for the `avatars` bucket compares the first folder
        // segment against `auth.uid()::text`, which Postgres always renders
        // in lowercase. `UUID.uuidString` on Swift returns uppercase hex,
        // so we MUST lowercase here or the insert is rejected with
        // "new row violates row-level security policy".
        let path = "\(userId.uuidString.lowercased())/avatar.\(ext)"

        _ = try await storage
            .from(Self.avatarsBucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: contentType, upsert: true)
            )

        let publicURL = try storage
            .from(Self.avatarsBucket)
            .getPublicURL(path: path)

        // Cache-bust by appending the upload timestamp so the new bytes
        // beat any previous cache entry for the same path.
        var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items.append(URLQueryItem(name: "v", value: String(Int(Date().timeIntervalSince1970))))
        components?.queryItems = items
        return components?.url?.absoluteString ?? publicURL.absoluteString
    }

    /// Persists the caller's preferred currency (3-letter ISO code) on their
    /// profile row. Upper-cases the input so we store the canonical form.
    @discardableResult
    func updateDefaultCurrency(_ code: String) async throws -> ProfileDTO {
        guard let userId = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }

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
