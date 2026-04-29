//
//  AddGroupViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Observation

@Observable
@MainActor
final class AddGroupViewModel {
    var name: String = ""
    var description: String = ""
    var defaultCurrency: String = UserPreferences.defaultCurrency
    /// Random-once avatar assignment for the group being created.
    var selectedAvatarKey: String = GroupAvatar.randomKey()
    var selectedMemberIds: Set<UUID> = []
    /// Accepted friends shown in the multi-select picker. Populated lazily by
    /// `loadFriends()` so the form can render selected names before submit.
    var availableFriends: [FriendRowItem] = []
    var isSubmitting: Bool = false
    var errorMessage: String?

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    /// Display label for the "Add Friends" row: either "Select friends" when
    /// none are picked or a comma-separated preview capped at 2 names.
    var selectedFriendsLabel: String {
        if selectedMemberIds.isEmpty { return "Select friends" }
        let chosen = availableFriends.filter { selectedMemberIds.contains($0.id) }
        let names = chosen.map(\.name)
        switch names.count {
        case 0: return "\(selectedMemberIds.count) selected"
        case 1: return names[0]
        case 2: return names.joined(separator: ", ")
        default: return "\(names[0]), \(names[1]) +\(names.count - 2)"
        }
    }

    private let service = GroupsService.shared
    private let friendsService = FriendsService.shared

    func loadFriends() async {
        do {
            let rows = try await friendsService.friendsWithBalances(status: .accepted)
            availableFriends = rows
                .map {
                    FriendRowItem(
                        id: $0.profile.id,
                        name: $0.profile.displayName,
                        avatarTint: AppColor.tint(for: $0.profile.id),
                        balance: $0.netOwed,
                        currency: $0.profile.defaultCurrency,
                        isPending: $0.isPending
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await service.create(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                defaultCurrency: defaultCurrency,
                avatarKey: selectedAvatarKey,
                memberUserIds: Array(selectedMemberIds)
            )
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }
}
