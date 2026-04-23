//
//  FriendsViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Splits the universe of "pending" friendships into two directional buckets:
//    - incomingRequests: someone asked to befriend me  → Accept / Decline.
//    - outgoingInvites:  I asked to befriend someone   → "Invite sent".
//  Out-of-band email/phone invites that have not been claimed yet stay under
//  pendingInvites and remain informational.
//

import Foundation
import Observation

@Observable
@MainActor
final class FriendsViewModel {
    var friends: [FriendRowItem] = []
    var incomingRequests: [FriendRowItem] = []
    var outgoingInvites: [FriendRowItem] = []
    var pendingInvites: [PendingInviteRowItem] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    /// Friend ids currently being mutated (accept/decline in flight). Used by
    /// the row to disable buttons and avoid double-taps.
    var pendingActionIds: Set<UUID> = []

    private let service = FriendsService.shared

    var filtered: [FriendRowItem] {
        Self.filter(friends, by: searchText)
    }

    var filteredIncoming: [FriendRowItem] {
        Self.filter(incomingRequests, by: searchText)
    }

    var filteredOutgoing: [FriendRowItem] {
        Self.filter(outgoingInvites, by: searchText)
    }

    var filteredPendingInvites: [PendingInviteRowItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return pendingInvites }
        return pendingInvites.filter { $0.label.lowercased().contains(q) }
    }

    var hasAnyOutgoing: Bool { !outgoingInvites.isEmpty || !pendingInvites.isEmpty }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let me = await SupabaseProvider.currentUserId() else {
                throw AppError.notAuthenticated
            }

            async let acceptedRel = service.friendsWithBalances(status: .accepted)
            async let pendingRel  = service.friendsWithBalances(status: .pending)
            async let pendingRows = service.friendships(status: .pending)
            async let invites     = service.pendingInvites()
            let (accepted, pendingFriends, pendingFriendships, outOfBand) =
                try await (acceptedRel, pendingRel, pendingRows, invites)

            // Map (counterpart_id → requested_by) so we can split direction.
            let requestedByByCounterpart: [UUID: UUID] = Dictionary(
                uniqueKeysWithValues: pendingFriendships.map {
                    ($0.counterparty(of: me), $0.requestedBy)
                }
            )

            friends = accepted.map(Self.makeRow)

            var incoming: [FriendRowItem] = []
            var outgoing: [FriendRowItem] = []
            for f in pendingFriends {
                let row = Self.makeRow(f)
                if requestedByByCounterpart[f.profile.id] == me {
                    outgoing.append(row)
                } else {
                    incoming.append(row)
                }
            }
            incomingRequests = incoming
            outgoingInvites  = outgoing
            pendingInvites   = outOfBand.compactMap(Self.makeInviteRow)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    // MARK: - Actions

    func acceptRequest(_ friend: FriendRowItem) async {
        guard !pendingActionIds.contains(friend.id) else { return }
        pendingActionIds.insert(friend.id)
        defer { pendingActionIds.remove(friend.id) }

        do {
            _ = try await service.accept(friend.id)
            // Move the row optimistically into the accepted list.
            incomingRequests.removeAll { $0.id == friend.id }
            var promoted = friend
            promoted.isPending = false
            friends.append(promoted)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func declineRequest(_ friend: FriendRowItem) async {
        guard !pendingActionIds.contains(friend.id) else { return }
        pendingActionIds.insert(friend.id)
        defer { pendingActionIds.remove(friend.id) }

        do {
            try await service.decline(friend.id)
            incomingRequests.removeAll { $0.id == friend.id }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    // MARK: - Mapping helpers

    private static func makeRow(_ f: FriendWithBalance) -> FriendRowItem {
        FriendRowItem(
            id: f.profile.id,
            name: f.profile.fullName ?? f.profile.username ?? "Friend",
            avatarTint: AppColor.tint(for: f.profile.id),
            balance: f.netOwed,
            currency: f.profile.defaultCurrency,
            isPending: f.isPending
        )
    }

    private static func makeInviteRow(_ inv: FriendInviteDTO) -> PendingInviteRowItem? {
        let label: String?
        switch inv.channel {
        case .email: label = inv.email
        case .phone: label = inv.phone
        }
        guard let label, !label.isEmpty else { return nil }
        return PendingInviteRowItem(
            id: inv.id,
            label: label,
            channel: inv.channel,
            avatarTint: AppColor.tint(for: inv.id)
        )
    }

    private static func filter(_ rows: [FriendRowItem], by query: String) -> [FriendRowItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return rows }
        return rows.filter { $0.name.lowercased().contains(q) }
    }
}
