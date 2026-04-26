//
//  NotificationsService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

@MainActor
final class NotificationsService {
    static let shared = NotificationsService()
    private var db: PostgrestClient { SupabaseProvider.db }

    func inbox(limit: Int = 50) async throws -> [NotificationDTO] {
        guard let me = await SupabaseProvider.currentUserId() else { throw AppError.notAuthenticated }
        return try await db.from("notifications")
            .select()
            .eq("user_id", value: me)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func markRead(_ id: UUID) async throws {
        struct Patch: Encodable {
            let is_read: Bool
            let read_at: String
        }
        let patch = Patch(is_read: true, read_at: ISO8601DateFormatter().string(from: Date()))
        try await db.from("notifications")
            .update(patch)
            .eq("id", value: id)
            .execute()
    }

    /// Calls the `send_test_push` Edge Function which dispatches an APNs
    /// alert to every device token registered for the current user.
    /// Surfaced from Settings → Notifications → "Send Test Push" so
    /// developers can validate the end-to-end pipeline without having
    /// to create an expense or settlement.
    func sendTestPush(title: String? = nil, body: String? = nil) async throws -> TestPushResult {
        struct Body: Encodable {
            let title: String?
            let body: String?
        }
        let payload = Body(title: title, body: body)
        return try await SupabaseProvider.functions.invoke(
            "send_test_push",
            options: FunctionInvokeOptions(method: .post, body: payload)
        )
    }
}

/// Decoded shape of the `send_test_push` Edge Function response.
struct TestPushResult: Decodable, Sendable {
    let userId: UUID
    let devices: Int
    let pushed: Int
    let failed: Int

    enum CodingKeys: String, CodingKey {
        case devices, pushed, failed
        case userId = "user_id"
    }
}

@MainActor
final class DeviceTokensService {
    static let shared = DeviceTokensService()
    private var db: PostgrestClient { SupabaseProvider.db }

    /// Call from `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    func register(token deviceToken: Data) async {
        guard let me = await SupabaseProvider.currentUserId() else { return }
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()

        struct Row: Encodable {
            let user_id: UUID
            let token: String
            let platform: String
            let last_seen_at: String
        }

        let row = Row(
            user_id: me, token: token, platform: "ios",
            last_seen_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try? await db.from("device_tokens")
            .upsert(row, onConflict: "token")
            .execute()
    }
}
