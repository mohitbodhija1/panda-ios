//
//  GroupsListViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Observation

@Observable
@MainActor
final class GroupsListViewModel {
    var groups: [GroupRowItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service = GroupsService.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let all = service.myGroups()
            async let balances = service.myBalanceAcrossGroups()
            async let members = service.myGroupMemberships()
            let (gs, bs, ms) = try await (all, balances, members)

            let balanceByGroup = Dictionary(uniqueKeysWithValues: bs.map { ($0.groupId, $0.balance) })
            let memberCountByGroup = Dictionary(grouping: ms, by: { $0.groupId }).mapValues(\.count)

            groups = gs.map {
                GroupRowItem(
                    id: $0.id,
                    name: $0.name,
                    memberCount: memberCountByGroup[$0.id] ?? 0,
                    yourBalance: balanceByGroup[$0.id] ?? 0,
                    currency: $0.defaultCurrency
                )
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
