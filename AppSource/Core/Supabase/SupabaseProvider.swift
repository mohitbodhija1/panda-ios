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
    static func currentUserId() async -> UUID? {
        try? await shared.auth.user().id
    }
}
