//
//  GroupsService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

@MainActor
final class GroupsService {
    static let shared = GroupsService()

    private var db: PostgrestClient { SupabaseProvider.db }

    func myGroups() async throws -> [GroupDTO] {
        try await db.from("groups")
            .select()
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func members(of groupId: UUID) async throws -> [GroupMemberDTO] {
        try await db.from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .execute()
            .value
    }

    /// Every group-membership row visible to the current user, across all of
    /// their groups. Used by list screens to render member-count badges
    /// without issuing one query per group.
    func myGroupMemberships() async throws -> [GroupMemberDTO] {
        try await db.from("group_members")
            .select()
            .execute()
            .value
    }

    func balances(for groupId: UUID) async throws -> [GroupBalanceDTO] {
        try await db.from("v_user_group_balance")
            .select()
            .eq("group_id", value: groupId)
            .execute()
            .value
    }

    func myBalanceAcrossGroups() async throws -> [GroupBalanceDTO] {
        guard let userId = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }
        return try await db.from("v_user_group_balance")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    func create(name: String, description: String?, defaultCurrency: String, memberUserIds: [UUID]) async throws -> GroupDTO {
        // Routed through rpc_create_group (SECURITY DEFINER) so `created_by`
        // is set from auth.uid() server-side. This avoids the
        // `groups_authed_insert` WITH CHECK failing when the client UUID and
        // the JWT subject drift (e.g. just-refreshed token race).
        struct Payload: Encodable {
            let name: String
            let description: String?
            let default_currency: String
            let member_ids: [UUID]
        }
        struct Wrapper: Encodable { let payload: Payload }

        let wrapper = Wrapper(payload: Payload(
            name: name,
            description: description,
            default_currency: defaultCurrency,
            member_ids: memberUserIds
        ))

        return try await db.rpc("rpc_create_group", params: wrapper)
            .single()
            .execute()
            .value
    }

    /// Owner-only: invite one or more existing profiles into a group.
    /// Routed through `rpc_add_group_members` (SECURITY DEFINER) so the
    /// caller's ownership is asserted from `auth.uid()` server-side and
    /// every successful insert also writes an `activity_log` row.
    /// Returns the number of new members actually added (idempotent).
    @discardableResult
    func addMembers(groupId: UUID, friendIds: [UUID]) async throws -> Int {
        guard !friendIds.isEmpty else { return 0 }
        struct Args: Encodable {
            let p_group_id: UUID
            let p_user_ids: [UUID]
        }
        return try await db
            .rpc("rpc_add_group_members",
                 params: Args(p_group_id: groupId, p_user_ids: friendIds))
            .single()
            .execute()
            .value
    }

    func leave(groupId: UUID) async throws {
        guard let me = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }
        try await db.from("group_members")
            .delete()
            .eq("group_id", value: groupId)
            .eq("user_id", value: me)
            .execute()
    }

    func archive(groupId: UUID) async throws {
        try await db.from("groups")
            .update(["is_archived": true])
            .eq("id", value: groupId)
            .execute()
    }
}
