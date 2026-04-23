//
//  CurrenciesService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Fetches the server-side currency catalog (`public.currencies`) used by the
//  currency picker. The table is public-readable, so no auth is required.
//

import Foundation
import Supabase

@MainActor
final class CurrenciesService {
    static let shared = CurrenciesService()

    private var db: PostgrestClient { SupabaseProvider.db }

    /// Process-wide cache so repeated picker opens don't re-hit the network.
    private var cache: [CurrencyDTO] = []

    func list(forceRefresh: Bool = false) async throws -> [CurrencyDTO] {
        if !forceRefresh, !cache.isEmpty { return cache }
        let rows: [CurrencyDTO] = try await db.from("currencies")
            .select()
            .order("code", ascending: true)
            .execute()
            .value
        cache = rows
        return rows
    }
}
