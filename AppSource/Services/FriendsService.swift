//
//  FriendsService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

struct FriendWithBalance: Identifiable, Hashable {
    let profile: ProfileDTO
    let netOwed: Decimal
    let status: FriendshipStatus
    var id: UUID { profile.id }

    var isPending: Bool { status == .pending }
}

@MainActor
final class FriendsService {
    static let shared = FriendsService()

    private var db: PostgrestClient { SupabaseProvider.db }

    func friendships(status: FriendshipStatus = .accepted) async throws -> [FriendshipDTO] {
        try await db.from("friendships")
            .select()
            .eq("status", value: status.rawValue)
            .execute()
            .value
    }

    func balances() async throws -> [FriendBalanceDTO] {
        try await db.from("v_user_friend_balance")
            .select()
            .execute()
            .value
    }

    /// Pending invites that target an email/phone for which no profile exists yet.
    func pendingInvites() async throws -> [FriendInviteDTO] {
        try await db.from("friend_invites")
            .select()
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Returns counterparties for the current user, optionally including pending
    /// friendships. Balances default to zero for pending rows (no expenses yet).
    func friendsWithBalances(status: FriendshipStatus = .accepted) async throws -> [FriendWithBalance] {
        guard let me = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }

        async let f = friendships(status: status)
        async let b: [FriendBalanceDTO] = (status == .accepted ? balances() : .init())
        let (rels, bals) = try await (f, b)

        let counterpartIds = rels.map { $0.counterparty(of: me) }
        guard !counterpartIds.isEmpty else { return [] }

        let profiles = try await db.from("profiles")
            .select()
            .in("id", values: counterpartIds.map { $0.uuidString })
            .execute()
            .value as [ProfileDTO]
        let profileById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        let balanceForCounterpart: (UUID) -> Decimal = { other in
            let pair = bals.first(where: {
                ($0.userA == me && $0.userB == other) ||
                ($0.userB == me && $0.userA == other)
            })
            return pair?.balance(for: me) ?? 0
        }

        return counterpartIds.compactMap { other in
            guard let profile = profileById[other] else { return nil }
            return FriendWithBalance(
                profile: profile,
                netOwed: balanceForCounterpart(other),
                status: status
            )
        }
    }

    func invite(channel: FriendInviteChannel, target: String) async throws {
        struct Args: Encodable { let channel: String; let target: String }
        try await db.rpc("rpc_invite_friend", params: Args(channel: channel.rawValue, target: target)).execute()
    }

    func accept(_ otherUserId: UUID) async throws -> FriendshipDTO {
        struct Args: Encodable { let other: UUID }
        return try await db.rpc("rpc_accept_friend", params: Args(other: otherUserId))
            .single()
            .execute()
            .value
    }

    /// Reject a pending friend request from `otherUserId`. Implemented as a
    /// direct delete because the `friendships_pair_delete` RLS policy already
    /// allows either party in the pair to drop the row.
    func decline(_ otherUserId: UUID) async throws {
        guard let me = try? await SupabaseProvider.auth.user().id else { throw AppError.notAuthenticated }
        let pair = [me, otherUserId].sorted { $0.uuidString < $1.uuidString }
        try await db.from("friendships")
            .delete()
            .eq("user_a", value: pair[0])
            .eq("user_b", value: pair[1])
            .eq("status", value: "pending")
            .execute()
    }
}
