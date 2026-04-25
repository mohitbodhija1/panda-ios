//
//  AddExpenseViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Drives the "Add Expense" full-screen cover. Supports two targets via the
//  `mode` segmented control:
//    1. .group  → equal-splits across the selected group's members.
//    2. .friend → a group-less 1-on-1 expense split equally between the
//       current user and the selected friend. Works even if the friendship
//       is still pending, as long as a profile exists.
//
//  Preselected entry points (from Group detail or a friend row) lock the
//  target and hide the segmented control.
//

import Foundation
import Observation

@Observable
@MainActor
final class AddExpenseViewModel {
    var mode: ExpenseTarget = .group

    var title: String = ""
    var emoji: String = "💸"
    var amountText: String = ""
    var notes: String = ""

    // Group target.
    var availableGroups: [GroupRowItem] = []
    var selectedGroupId: UUID?
    var groupMembers: [ProfileDTO] = []

    // Friend target.
    var availableFriends: [FriendRowItem] = []
    var selectedFriendId: UUID?

    /// Preselection from upstream surfaces (group detail, friend row tap).
    /// When set, the corresponding mode is locked.
    let preselectedGroup: GroupRowItem?
    let preselectedFriend: FriendRowItem?

    var currency: String = UserPreferences.defaultCurrency
    var isSubmitting: Bool = false
    var errorMessage: String?

    /// True when the entry point pinned us to a single target. The view uses
    /// this to hide the segmented control.
    var isModeLocked: Bool { preselectedGroup != nil || preselectedFriend != nil }

    var selectedFriend: FriendRowItem? {
        if let pre = preselectedFriend { return pre }
        return availableFriends.first(where: { $0.id == selectedFriendId })
    }

    var selectedGroup: GroupRowItem? {
        availableGroups.first(where: { $0.id == selectedGroupId })
    }

    var parsedAmount: Decimal? {
        let cleaned = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned).flatMap { $0 > 0 ? $0 : nil }
    }

    var canSubmit: Bool {
        let titleOk = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let amountOk = parsedAmount != nil
        guard titleOk, amountOk, !isSubmitting else { return false }
        switch mode {
        case .group:   return selectedGroupId != nil && !groupMembers.isEmpty
        case .friends: return selectedFriend != nil
        }
    }

    private let groupsService = GroupsService.shared
    private let friendsService = FriendsService.shared
    private let expensesService = ExpensesService.shared
    private let profiles = ProfilesService.shared

    init(preselectedGroup: GroupRowItem? = nil, preselectedFriend: FriendRowItem? = nil) {
        self.preselectedGroup = preselectedGroup
        self.preselectedFriend = preselectedFriend

        if let friend = preselectedFriend {
            mode = .friends
            selectedFriendId = friend.id
            availableFriends = [friend]
            currency = friend.currency
            return
        }
        if let g = preselectedGroup {
            mode = .group
            availableGroups = [g]
            selectedGroupId = g.id
            currency = g.currency
        }
    }

    func load() async {
        // Load both lists once unless we're locked to a single preselection
        // (which already populated the relevant array in init).
        await withTaskGroup(of: Void.self) { tasks in
            if preselectedGroup == nil {
                tasks.addTask { await self.loadGroups() }
            }
            if preselectedFriend == nil {
                tasks.addTask { await self.loadFriends() }
            }
        }
        if mode == .group { await loadMembers() }
    }

    private func loadGroups() async {
        do {
            async let gs = groupsService.myGroups()
            async let bs = groupsService.myBalanceAcrossGroups()
            async let mems = groupsService.myGroupMemberships()
            let (groups, balances, members) = try await (gs, bs, mems)

            let balanceByGroup = Dictionary(uniqueKeysWithValues: balances.map { ($0.groupId, $0.balance) })
            let memberCount = Dictionary(grouping: members, by: { $0.groupId }).mapValues(\.count)

            availableGroups = groups.map {
                GroupRowItem(
                    id: $0.id,
                    name: $0.name,
                    memberCount: memberCount[$0.id] ?? 0,
                    yourBalance: balanceByGroup[$0.id] ?? 0,
                    currency: $0.defaultCurrency
                )
            }
            if mode == .group, selectedGroupId == nil {
                selectedGroupId = availableGroups.first?.id
                syncCurrencyWithSelectedGroup()
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func loadFriends() async {
        do {
            async let accepted = friendsService.friendsWithBalances(status: .accepted)
            async let pending  = friendsService.friendsWithBalances(status: .pending)
            let (acc, pen) = try await (accepted, pending)

            let rows = (acc + pen).map {
                FriendRowItem(
                    id: $0.profile.id,
                    name: $0.profile.displayName,
                    avatarTint: AppColor.tint(for: $0.profile.id),
                    balance: $0.netOwed,
                    currency: $0.profile.defaultCurrency,
                    isPending: $0.isPending
                )
            }
            availableFriends = rows
            if mode == .friends, selectedFriendId == nil {
                selectedFriendId = rows.first?.id
                syncCurrencyWithSelectedFriend()
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    /// Called by the view when the user toggles the segmented control. Loads
    /// the membership list when switching into group mode if needed, and
    /// re-aligns the currency hint to the newly selected target.
    func didChangeMode(to newMode: ExpenseTarget) {
        mode = newMode
        switch newMode {
        case .group:
            if selectedGroupId == nil { selectedGroupId = availableGroups.first?.id }
            syncCurrencyWithSelectedGroup()
            Task { await loadMembers() }
        case .friends:
            if selectedFriendId == nil { selectedFriendId = availableFriends.first?.id }
            syncCurrencyWithSelectedFriend()
        }
    }

    /// When the user picks a different group, align the default currency with
    /// that group. Users can still override via the picker afterwards.
    func syncCurrencyWithSelectedGroup() {
        guard mode == .group, let group = selectedGroup else { return }
        currency = group.currency
    }

    func syncCurrencyWithSelectedFriend() {
        guard mode == .friends, let friend = selectedFriend else { return }
        currency = friend.currency
    }

    func loadMembers() async {
        guard mode == .group, let gid = selectedGroupId else {
            groupMembers = []
            return
        }
        do {
            let rows = try await groupsService.members(of: gid)
            let ids = rows.map(\.userId)
            var profilesList: [ProfileDTO] = []
            for id in ids {
                if let p = try? await profiles.fetch(id: id) {
                    profilesList.append(p)
                }
            }
            groupMembers = profilesList
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func submit() async -> Bool {
        guard canSubmit,
              let amount = parsedAmount,
              let payerId = await SupabaseProvider.currentUserId()
        else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // yyyy-MM-dd

        let groupId: UUID?
        let splits: [CreateExpenseInput.Split]
        switch mode {
        case .friends:
            guard let friend = selectedFriend else { return false }
            groupId = nil
            splits = [
                CreateExpenseInput.Split(user_id: payerId, share_count: 1),
                CreateExpenseInput.Split(user_id: friend.id, share_count: 1)
            ]
        case .group:
            guard let gid = selectedGroupId else { return false }
            groupId = gid
            splits = groupMembers.map { CreateExpenseInput.Split(user_id: $0.id, share_count: 1) }
        }

        let input = CreateExpenseInput(
            group_id: groupId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            emoji: emoji,
            category_id: nil,
            amount: amount,
            currency: currency,
            paid_by: payerId,
            expense_date: String(today),
            split_type: .equal,
            splits: splits
        )

        do {
            _ = try await expensesService.create(input)
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }
}
