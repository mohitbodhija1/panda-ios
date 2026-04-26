//
//  SupabaseProvider.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Single point of access to the Supabase client. The supabase-swift SPM
//  package must be added once via Xcode (see supabase/README.md for setup).
//

import Foundation
import Supabase

enum SupabaseProvider {
    static let shared: SupabaseClient = SupabaseClient(
        supabaseURL: SupabaseEnvironment.url,
        supabaseKey: SupabaseEnvironment.anonKey
    )

    static var auth: AuthClient { shared.auth }
    static var db: PostgrestClient { shared.database }
    static var rpc: PostgrestClient { shared.database }
    static var storage: SupabaseStorageClient { shared.storage }
    static var functions: FunctionsClient { shared.functions }

    /// Non-throwing convenience that hides the `Auth.User` type from view-model
    /// call sites so Features/ files don't need to `import Supabase`.
    ///
    /// IMPORTANT: This intentionally reads from the locally cached session
    /// (`auth.currentUser`) and does *not* call `auth.user()` — the latter
    /// performs a `GET /auth/v1/user` round trip and used to surface a
    /// spurious "You need to sign in to do that" error when the network
    /// blip swallowed by `try?`. The cached user is the source of truth
    /// while a session is loaded; it stays in sync with refresh/sign-out.
    static func currentUserId() async -> UUID? {
        shared.auth.currentUser?.id
    }
}
