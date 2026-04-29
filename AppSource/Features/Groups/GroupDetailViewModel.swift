//
//  GroupDetailViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Observation
import SwiftUI

/// One row in the Members tab of a group. Mirrors `FriendRowItem` chrome but
/// carries the role badge so owners are visually distinguishable.
struct GroupMemberRowItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let avatarTint: Color
    let role: GroupMemberRole
    let isCurrentUser: Bool
}

@Observable
@MainActor
final class GroupDetailViewModel {
    let group: GroupRowItem

    /// Mutable display name kept in sync with the latest server state so
    /// renames reflect in the nav bar without re-creating the view.
    var displayName: String
    /// Mutable avatar key so owner changes reflect immediately in the hero.
    var avatarKey: String?

    var expenses: [ExpenseRowItem] = []
    /// Lookup table backing tap-to-edit on expense rows. Mirrors the order
    /// of `expenses` and lets the view resolve the full DTO without an
    /// extra round-trip to Postgres.
    var expensesById: [UUID: ExpenseDTO] = [:]
    var members: [GroupMemberRowItem] = []
    var memberIds: Set<UUID> = []
    var isOwner: Bool = false
    var totalExpenses: Decimal = 0
    var youOwe: Decimal = 0
    var youAreOwed: Decimal = 0
    var isLoading: Bool = false
    var isAddingMembers: Bool = false
    var isRenaming: Bool = false
    var isUpdatingAvatar: Bool = false
    /// Tracks per-member removal so the row can show a spinner without
    /// blocking the rest of the screen.
    var removingMemberIds: Set<UUID> = []
    var errorMessage: String?

    private let expensesService = ExpensesService.shared
    private let groupsService = GroupsService.shared
    private let profiles = ProfilesService.shared

    init(group: GroupRowItem) {
        self.group = group
        self.displayName = group.name
        self.avatarKey = group.avatarKey
        if group.yourBalance > 0 { youAreOwed = group.yourBalance }
        if group.yourBalance < 0 { youOwe = -group.yourBalance }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let exps = expensesService.list(groupId: group.id)
            async let bals = groupsService.balances(for: group.id)
            async let mems = groupsService.members(of: group.id)
            let (es, bs, ms) = try await (exps, bals, mems)

            totalExpenses = es.reduce(Decimal(0)) { $0 + $1.amount }

            let meId = await SupabaseProvider.currentUserId()
            if let me = meId, let mine = bs.first(where: { $0.userId == me }) {
                youOwe = mine.balance < 0 ? -mine.balance : 0
                youAreOwed = mine.balance > 0 ? mine.balance : 0
            }
            isOwner = ms.contains { $0.userId == meId && $0.role == .owner }
            memberIds = Set(ms.map(\.userId))

            let memberProfiles = try await fetchProfiles(ids: ms.map(\.userId))
            let profileById = Dictionary(uniqueKeysWithValues: memberProfiles.map { ($0.id, $0) })

            members = ms
                .map { m in
                    let profile = profileById[m.userId]
                    return GroupMemberRowItem(
                        id: m.userId,
                        name: profile?.displayName ?? "Member",
                        avatarTint: AppColor.tint(for: m.userId),
                        role: m.role,
                        isCurrentUser: m.userId == meId
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.role != rhs.role { return lhs.role == .owner }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }

            let nameByUserId = Dictionary(uniqueKeysWithValues: memberProfiles.map {
                ($0.id, $0.displayName)
            })

            expenses = es.map { e in
                let payerName = e.paidBy == meId
                    ? "You"
                    : (nameByUserId[e.paidBy] ?? "Someone")
                return ExpenseRowItem(
                    id: e.id,
                    title: e.title,
                    emoji: e.emoji ?? "💸",
                    subtitle: "Paid by \(payerName) · \(RelativeDateFormatters.short(fromISODay: e.expenseDate))",
                    amount: e.amount,
                    currency: e.currency
                )
            }
            expensesById = Dictionary(uniqueKeysWithValues: es.map { ($0.id, $0) })
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    /// Owner-only: add the picked friends to this group via
    /// `rpc_add_group_members` and refresh local state.
    func addMembers(friendIds: Set<UUID>) async {
        let toAdd = friendIds.subtracting(memberIds)
        guard !toAdd.isEmpty, !isAddingMembers else { return }
        isAddingMembers = true
        errorMessage = nil
        defer { isAddingMembers = false }

        do {
            _ = try await groupsService.addMembers(
                groupId: group.id,
                friendIds: Array(toAdd)
            )
            await load()
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    /// Owner-only: rename the group. Optimistically updates `displayName`
    /// so the nav title changes the moment the request is in flight, and
    /// rolls back on failure. Returns true on success so callers can
    /// dismiss any open editor.
    @discardableResult
    func rename(to newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed != displayName,
              !isRenaming else { return false }

        let previous = displayName
        displayName = trimmed
        isRenaming = true
        errorMessage = nil
        defer { isRenaming = false }

        do {
            _ = try await groupsService.rename(groupId: group.id, to: trimmed)
            return true
        } catch {
            displayName = previous
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }

    /// Removes a single member from the group. Owners can remove anyone;
    /// for self-removal the dedicated leave flow is preferred.
    func removeMember(_ member: GroupMemberRowItem) async {
        guard !removingMemberIds.contains(member.id) else { return }
        removingMemberIds.insert(member.id)
        errorMessage = nil
        defer { removingMemberIds.remove(member.id) }

        do {
            try await groupsService.removeMember(groupId: group.id, userId: member.id)
            members.removeAll { $0.id == member.id }
            memberIds.remove(member.id)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    /// Owner-only: set one of the predefined avatar keys for the group.
    func updateAvatar(to newKey: String) async {
        guard GroupAvatar.keys.contains(newKey),
              newKey != avatarKey,
              !isUpdatingAvatar else { return }

        let previous = avatarKey
        avatarKey = newKey
        isUpdatingAvatar = true
        errorMessage = nil
        defer { isUpdatingAvatar = false }

        do {
            _ = try await groupsService.updateAvatar(groupId: group.id, avatarKey: newKey)
        } catch {
            avatarKey = previous
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func fetchProfiles(ids: [UUID]) async throws -> [ProfileDTO] {
        guard !ids.isEmpty else { return [] }
        var results: [ProfileDTO] = []
        for id in ids {
            if let p = try? await profiles.fetch(id: id) {
                results.append(p)
            }
        }
        return results
    }
}
