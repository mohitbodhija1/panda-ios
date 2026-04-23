//
//  GroupDetailViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Observation

@Observable
@MainActor
final class GroupDetailViewModel {
    let group: GroupRowItem

    var expenses: [ExpenseRowItem] = []
    var totalExpenses: Decimal = 0
    var youOwe: Decimal = 0
    var youAreOwed: Decimal = 0
    var isLoading: Bool = false
    var errorMessage: String?

    private let expensesService = ExpensesService.shared
    private let groupsService = GroupsService.shared
    private let profiles = ProfilesService.shared

    init(group: GroupRowItem) {
        self.group = group
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
            let (es, bs) = try await (exps, bals)

            totalExpenses = es.reduce(Decimal(0)) { $0 + $1.amount }

            let meId = await SupabaseProvider.currentUserId()
            if let me = meId, let mine = bs.first(where: { $0.userId == me }) {
                youOwe = mine.balance < 0 ? -mine.balance : 0
                youAreOwed = mine.balance > 0 ? mine.balance : 0
            }

            let payerIds = Set(es.map { $0.paidBy })
            let payerProfiles = try await fetchProfiles(ids: Array(payerIds))
            let nameByUserId = Dictionary(uniqueKeysWithValues: payerProfiles.map {
                ($0.id, $0.fullName ?? $0.username ?? "Unknown")
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
        } catch {
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
