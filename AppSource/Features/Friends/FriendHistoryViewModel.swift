//
//  FriendHistoryViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Backs the per-friend history screen reachable by tapping a friend tile.
//  Surfaces every expense + settlement between the current user and the
//  selected friend (across groups and 1-to-1), plus a running balance header
//  reused from the friend-balance view (positive = friend owes me).
//

import Foundation
import Observation

@Observable
@MainActor
final class FriendHistoryViewModel {
    let friend: FriendRowItem

    var entries: [FriendLedgerEntryDTO] = []
    var balance: Decimal = 0
    var currency: String
    var isLoading: Bool = false
    var errorMessage: String?

    private let friendsService = FriendsService.shared

    init(friend: FriendRowItem) {
        self.friend = friend
        self.balance = friend.balance
        self.currency = friend.currency
    }

    /// Positive part of the running balance: the money this friend owes the
    /// current user across all shared activity.
    var youAreOwed: Decimal { balance > 0 ? balance : 0 }

    /// Negative part of the running balance, surfaced as a positive magnitude.
    var youOwe: Decimal { balance < 0 ? -balance : 0 }

    var isSettled: Bool { balance == 0 }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let ledger = friendsService.ledger(with: friend.id)
            async let balances = friendsService.balances()
            let (rows, bals) = try await (ledger, balances)

            entries = rows

            if let me = await SupabaseProvider.currentUserId(),
               let pair = bals.first(where: {
                   ($0.userA == me && $0.userB == friend.id) ||
                   ($0.userB == me && $0.userA == friend.id)
               })
            {
                balance = pair.balance(for: me)
            } else {
                balance = friend.balance
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
