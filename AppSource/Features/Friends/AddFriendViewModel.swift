//
//  AddFriendViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Observation

@Observable
@MainActor
final class AddFriendViewModel {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    var canSubmit: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && !isSubmitting
    }

    private let service = FriendsService.shared

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await service.invite(channel: .email, target: email.trimmingCharacters(in: .whitespacesAndNewlines))
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }
}
