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
    private enum LastEditedShare {
        case mine
        case friend
    }

    var mode: ExpenseTarget = .group

    var title: String = ""
    var emoji: String = "💸"
    var amountText: String = ""
    var notes: String = ""
    /// Friends-mode distribution (exact amounts). Used only in create mode.
    var myShareText: String = ""
    var friendShareText: String = ""
    private var lastEditedShare: LastEditedShare?

    // Group target.
    var availableGroups: [GroupRowItem] = []
    var selectedGroupId: UUID?
    var groupMembers: [ProfileDTO] = []
    /// Create-mode participant selection for group expenses.
    var selectedGroupMemberIds: Set<UUID> = []

    // Friend target.
    var availableFriends: [FriendRowItem] = []
    var selectedFriendId: UUID?

    /// Preselection from upstream surfaces (group detail, friend row tap).
    /// When set, the corresponding mode is locked.
    let preselectedGroup: GroupRowItem?
    let preselectedFriend: FriendRowItem?

    /// When non-nil the view is in *edit* mode: we patch the existing
    /// expense via `rpc_update_expense` instead of creating a new one,
    /// keep the original participant set, and lock the target.
    let editingExpenseId: UUID?
    /// User ids of the original splits — preserved verbatim on save so an
    /// edit never silently adds/removes participants.
    private var lockedParticipantIds: [UUID] = []
    /// The original payer for the expense being edited. We preserve it on
    /// save so editing the amount can't accidentally change who paid.
    private var lockedPayerId: UUID?
    /// The original `expense_date` (yyyy-MM-dd) when editing; preserved
    /// so the activity timeline isn't reordered by an amount-only tweak.
    private var lockedExpenseDate: String?
    /// Original split type for the edited expense (we don't expose the
    /// split type picker yet so we keep it stable).
    private var lockedSplitType: SplitType = .equal

    var currency: String = UserPreferences.defaultCurrency
    var isSubmitting: Bool = false
    var errorMessage: String?

    /// True when the entry point pinned us to a single target. The view uses
    /// this to hide the segmented control.
    var isModeLocked: Bool { preselectedGroup != nil || preselectedFriend != nil || isEditing }

    /// True when the view is editing an existing expense.
    var isEditing: Bool { editingExpenseId != nil }

    var screenTitle: String { isEditing ? "Edit Expense" : "Add Expense" }
    var primaryActionTitle: String {
        if isSubmitting { return isEditing ? "Saving…" : "Adding…" }
        return isEditing ? "Save Changes" : "Add Expense"
    }

    var selectedFriend: FriendRowItem? {
        if let pre = preselectedFriend { return pre }
        return availableFriends.first(where: { $0.id == selectedFriendId })
    }

    var selectedGroup: GroupRowItem? {
        availableGroups.first(where: { $0.id == selectedGroupId })
    }

    var parsedAmount: Decimal? {
        parseDecimal(amountText).flatMap { $0 > 0 ? $0 : nil }
    }

    var parsedMyShare: Decimal? {
        parseDecimal(myShareText).flatMap { $0 >= 0 ? $0 : nil }
    }

    var parsedFriendShare: Decimal? {
        parseDecimal(friendShareText).flatMap { $0 >= 0 ? $0 : nil }
    }

    /// Friends-mode exact split must sum to total amount (± 0.01 tolerance).
    var isFriendSplitValid: Bool {
        guard let amount = parsedAmount,
              let mine = parsedMyShare,
              let friend = parsedFriendShare
        else { return false }
        return abs((mine + friend) - amount) <= 0.01
    }

    var canSubmit: Bool {
        let titleOk = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let amountOk = parsedAmount != nil
        guard titleOk, amountOk, !isSubmitting else { return false }

        // In edit mode the participants come from the original splits we
        // already loaded; we just need to know we have at least one.
        if isEditing { return !lockedParticipantIds.isEmpty }

        switch mode {
        case .group:
            return selectedGroupId != nil && !groupMembers.isEmpty && !selectedGroupMemberIds.isEmpty
        case .friends: return selectedFriend != nil && isFriendSplitValid
        }
    }

    private let groupsService = GroupsService.shared
    private let friendsService = FriendsService.shared
    private let expensesService = ExpensesService.shared
    private let profiles = ProfilesService.shared

    init(preselectedGroup: GroupRowItem? = nil, preselectedFriend: FriendRowItem? = nil) {
        self.preselectedGroup = preselectedGroup
        self.preselectedFriend = preselectedFriend
        self.editingExpenseId = nil

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

    /// Edit-mode initializer. Pre-fills every form field from the existing
    /// expense and locks the target so users can only tweak title / amount
    /// / emoji / currency / notes without accidentally changing the
    /// participants. `friendHint` lets callers pass the counterparty
    /// `FriendRowItem` so the row label reads as a name instead of an id.
    init(editingExpense expense: ExpenseDTO,
         friendHint: FriendRowItem? = nil,
         groupHint: GroupRowItem? = nil)
    {
        self.editingExpenseId = expense.id
        self.lockedPayerId = expense.paidBy
        self.lockedExpenseDate = expense.expenseDate
        self.lockedSplitType = expense.splitType

        self.title = expense.title
        self.notes = expense.notes ?? ""
        self.emoji = expense.emoji ?? "💸"
        self.amountText = NSDecimalNumber(decimal: expense.amount).stringValue
        self.currency = expense.currency

        if let groupId = expense.groupId {
            self.preselectedFriend = nil
            let group = groupHint ?? GroupRowItem(
                id: groupId,
                name: "Group",
                memberCount: 0,
                yourBalance: 0,
                currency: expense.currency,
                avatarKey: nil
            )
            self.preselectedGroup = group
            self.mode = .group
            self.availableGroups = [group]
            self.selectedGroupId = groupId
        } else {
            self.preselectedGroup = nil
            // Friend expenses always have exactly two participants — the
            // counterparty's name will be filled in when `load()` resolves
            // the splits and (optionally) the friendHint.
            if let friendHint {
                self.preselectedFriend = friendHint
                self.availableFriends = [friendHint]
                self.selectedFriendId = friendHint.id
            } else {
                self.preselectedFriend = nil
            }
            self.mode = .friends
        }
    }

    func load() async {
        if isEditing {
            await loadEditingContext()
            return
        }
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

    /// Loads the splits for the expense currently being edited so we know
    /// the original participant set, then mirrors the create flow's
    /// `groupMembers` array to keep the "Split Between" hint accurate.
    private func loadEditingContext() async {
        guard let expenseId = editingExpenseId else { return }
        do {
            let splits = try await expensesService.splits(for: expenseId)
            lockedParticipantIds = splits.map(\.userId)

            // Resolve participant profiles so the "Split Between" hint
            // shows a sensible count regardless of the original surface.
            var profilesList: [ProfileDTO] = []
            for id in lockedParticipantIds {
                if let p = try? await profiles.fetch(id: id) {
                    profilesList.append(p)
                }
            }
            groupMembers = profilesList
            selectedGroupMemberIds = Set(lockedParticipantIds)

            // For friend expenses, derive the counterparty so the row
            // shows their name (not just "Friend") even when no hint
            // was passed in.
            if mode == .friends, selectedFriendId == nil,
               let me = await SupabaseProvider.currentUserId(),
               let other = lockedParticipantIds.first(where: { $0 != me }),
               let counterparty = try? await profiles.fetch(id: other)
            {
                let row = FriendRowItem(
                    id: counterparty.id,
                    name: counterparty.displayName,
                    avatarTint: AppColor.tint(for: counterparty.id),
                    balance: 0,
                    currency: counterparty.defaultCurrency,
                    isPending: false
                )
                availableFriends = [row]
                selectedFriendId = row.id
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
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
                    currency: $0.defaultCurrency,
                    avatarKey: $0.avatarUrl
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
            seedEqualFriendSplitIfNeeded()
        }
    }

    /// Keeps friend split sensible while typing total amount:
    /// if both share fields are still blank, prefill with equal split.
    func handleAmountChanged() {
        guard mode == .friends, !isEditing else { return }
        guard let amount = parsedAmount else { return }

        // Fresh form: first amount entry seeds equal split.
        if myShareText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           friendShareText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            applyEqualSplit(for: amount)
            return
        }

        // Keep both shares synchronized with the updated total.
        switch lastEditedShare {
        case .mine:
            guard let mine = parsedMyShare else { return }
            let clampedMine = min(max(mine, 0), amount)
            if clampedMine != mine {
                myShareText = NSDecimalNumber(decimal: clampedMine.rounded(scale: 2)).stringValue
            }
            let friend = (amount - clampedMine).rounded(scale: 2)
            friendShareText = NSDecimalNumber(decimal: friend).stringValue
        case .friend:
            guard let theirs = parsedFriendShare else { return }
            let clampedFriend = min(max(theirs, 0), amount)
            if clampedFriend != theirs {
                friendShareText = NSDecimalNumber(decimal: clampedFriend.rounded(scale: 2)).stringValue
            }
            let mine = (amount - clampedFriend).rounded(scale: 2)
            myShareText = NSDecimalNumber(decimal: mine).stringValue
        case nil:
            applyEqualSplit(for: amount)
        }
    }

    /// User edited "Your Share" → keep total invariant by auto-updating friend share.
    func handleMyShareChanged() {
        guard mode == .friends, !isEditing else { return }
        lastEditedShare = .mine
        guard let amount = parsedAmount, let mine = parsedMyShare else { return }
        let clampedMine = min(max(mine, 0), amount)
        if clampedMine != mine {
            myShareText = NSDecimalNumber(decimal: clampedMine.rounded(scale: 2)).stringValue
        }
        let friend = (amount - clampedMine).rounded(scale: 2)
        friendShareText = NSDecimalNumber(decimal: friend).stringValue
    }

    /// User edited "Friend Share" → keep total invariant by auto-updating your share.
    func handleFriendShareChanged() {
        guard mode == .friends, !isEditing else { return }
        lastEditedShare = .friend
        guard let amount = parsedAmount, let theirs = parsedFriendShare else { return }
        let clampedFriend = min(max(theirs, 0), amount)
        if clampedFriend != theirs {
            friendShareText = NSDecimalNumber(decimal: clampedFriend.rounded(scale: 2)).stringValue
        }
        let mine = (amount - clampedFriend).rounded(scale: 2)
        myShareText = NSDecimalNumber(decimal: mine).stringValue
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
            let loadedIds = Set(groupMembers.map(\.id))
            selectedGroupMemberIds = selectedGroupMemberIds.intersection(loadedIds)
            if selectedGroupMemberIds.isEmpty {
                selectedGroupMemberIds = loadedIds
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func submit() async -> Bool {
        guard canSubmit, let amount = parsedAmount else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            if isEditing {
                _ = try await submitEdit(amount: amount)
            } else {
                _ = try await submitCreate(amount: amount)
            }
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }

    private func submitCreate(amount: Decimal) async throws -> ExpenseDTO {
        guard let payerId = await SupabaseProvider.currentUserId() else {
            throw AppError.notAuthenticated
        }
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // yyyy-MM-dd

        let groupId: UUID?
        let splits: [CreateExpenseInput.Split]
        switch mode {
        case .friends:
            guard let friend = selectedFriend else { throw AppError.validation("Pick a friend") }
            guard let mine = parsedMyShare, let theirs = parsedFriendShare else {
                throw AppError.validation("Enter how much each person owes.")
            }
            guard abs((mine + theirs) - amount) <= 0.01 else {
                throw AppError.validation("Distributed amount must equal the total.")
            }
            groupId = nil
            splits = [
                CreateExpenseInput.Split(user_id: payerId, amount_owed: mine),
                CreateExpenseInput.Split(user_id: friend.id, amount_owed: theirs)
            ]
        case .group:
            guard let gid = selectedGroupId else { throw AppError.validation("Pick a group") }
            let splitUserIds = groupMembers
                .map(\.id)
                .filter { selectedGroupMemberIds.contains($0) }
            guard !splitUserIds.isEmpty else {
                throw AppError.validation("Select at least one member to split this expense.")
            }
            groupId = gid
            splits = splitUserIds.map { CreateExpenseInput.Split(user_id: $0, share_count: 1) }
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
            split_type: mode == .friends ? .exact : .equal,
            splits: splits
        )
        return try await expensesService.create(input)
    }

    private func submitEdit(amount: Decimal) async throws -> ExpenseDTO {
        guard let expenseId = editingExpenseId else {
            throw AppError.validation("Missing expense id")
        }
        guard !lockedParticipantIds.isEmpty else {
            throw AppError.validation("Original participants not loaded")
        }

        let splits = lockedParticipantIds.map {
            CreateExpenseInput.Split(user_id: $0, share_count: 1)
        }

        let input = UpdateExpenseInput(
            expense_id: expenseId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            emoji: emoji,
            amount: amount,
            currency: currency,
            expense_date: lockedExpenseDate ?? String(ISO8601DateFormatter().string(from: Date()).prefix(10)),
            split_type: lockedSplitType,
            splits: splits
        )

        // The locked payer is preserved server-side because the update RPC
        // never touches `paid_by`. We keep the property here for future
        // multi-payer support without changing the call site.
        _ = lockedPayerId
        return try await expensesService.update(input)
    }

    private func parseDecimal(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned)
    }

    /// Prefill equal shares only when both fields are empty.
    private func seedEqualFriendSplitIfNeeded() {
        guard myShareText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              friendShareText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let amount = parsedAmount
        else { return }

        applyEqualSplit(for: amount)
    }

    private func applyEqualSplit(for amount: Decimal) {
        let half = (amount / 2).rounded(scale: 2)
        myShareText = NSDecimalNumber(decimal: half).stringValue
        friendShareText = NSDecimalNumber(decimal: (amount - half).rounded(scale: 2)).stringValue
    }

    func isGroupMemberSelected(_ memberId: UUID) -> Bool {
        selectedGroupMemberIds.contains(memberId)
    }

    func toggleGroupMember(_ memberId: UUID) {
        guard mode == .group, !isEditing else { return }
        if selectedGroupMemberIds.contains(memberId) {
            selectedGroupMemberIds.remove(memberId)
        } else {
            selectedGroupMemberIds.insert(memberId)
        }
    }

    func selectAllGroupMembers() {
        guard mode == .group, !isEditing else { return }
        selectedGroupMemberIds = Set(groupMembers.map(\.id))
    }

    func clearSelectedGroupMembers() {
        guard mode == .group, !isEditing else { return }
        selectedGroupMemberIds.removeAll()
    }
}

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .bankers)
        return result
    }
}
