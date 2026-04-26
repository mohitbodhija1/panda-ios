//
//  ActivityService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

@MainActor
final class ActivityService {
    static let shared = ActivityService()

    private var db: PostgrestClient { SupabaseProvider.db }

    func recent(limit: Int = 30) async throws -> [ActivityDTO] {
        guard let me = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }
        return try await db.from("v_recent_activity")
            .select()
            .eq("user_id", value: me)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}

@MainActor
final class HomeService {
    static let shared = HomeService()
    private var db: PostgrestClient { SupabaseProvider.db }

    func summary() async throws -> HomeSummaryDTO? {
        guard let me = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }
        let rows: [HomeSummaryDTO] = try await db.from("v_home_summary")
            .select()
            .eq("user_id", value: me)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}
