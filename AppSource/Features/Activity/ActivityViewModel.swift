//
//  ActivityViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Observation

@Observable
@MainActor
final class ActivityViewModel {
    var feed: [ActivityItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service = ActivityService.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let rows = try await service.recent(limit: 100)
            feed = rows.map(mapRow)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func mapRow(_ a: ActivityDTO) -> ActivityItem {
        let (title, subtitle) = labels(for: a.kind)
        return ActivityItem(
            id: a.id,
            title: title,
            subtitle: subtitle,
            delta: 0,
            currency: a.currencyDisplayCode(fallback: UserPreferences.defaultCurrency),
            dateLabel: RelativeDateFormatters.short(from: a.createdAt),
            avatarTint: AppColor.tint(for: a.actorId)
        )
    }

    private func labels(for kind: ActivityKind) -> (String, String) {
        switch kind {
        case .expenseCreated:     return ("New expense", "Added to a group")
        case .expenseUpdated:     return ("Expense updated", "Details changed")
        case .expenseDeleted:     return ("Expense removed", "Deleted from group")
        case .settlementCreated:  return ("Settlement", "Someone settled up")
        case .groupCreated:       return ("New group", "You were added")
        case .memberAdded:        return ("Member added", "Group changed")
        case .memberRemoved:      return ("Member removed", "Group changed")
        case .friendshipAccepted: return ("New friend", "You're now connected")
        case .commentAdded:       return ("Comment", "New message on an expense")
        }
    }
}
