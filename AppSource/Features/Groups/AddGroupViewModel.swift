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
    var selectedMemberIds: Set<UUID> = []
    var isSubmitting: Bool = false
    var errorMessage: String?

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    private let service = GroupsService.shared

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
                memberUserIds: Array(selectedMemberIds)
            )
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }
}
