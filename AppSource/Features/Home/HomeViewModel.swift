//
//  HomeViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Aggregates the three data sources the Home screen cares about:
//   - Personal balance summary (`v_home_summary`)
//   - Top few groups with balances (`groups` + `v_user_group_balance`)
//   - Recent activity feed (`v_recent_activity`)
//

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var firstName: String = ""
    /// Profile default; used on the Home landing card for icon + balance formatting.
    var landingCurrency: String = UserPreferences.fallbackCurrency
    var youOwe: Decimal = 0
    var youAreOwed: Decimal = 0
    var owedGroupsCount: Int = 0
    var owedFromCount: Int = 0
    var groups: [GroupRowItem] = []
    var recentActivity: [ActivityItem] = []

    var isLoading: Bool = false
    var errorMessage: String?

    private let profiles = ProfilesService.shared
    private let groupsService = GroupsService.shared
    private let friendsService = FriendsService.shared
    private let homeService = HomeService.shared
    private let activityService = ActivityService.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let profile = profiles.me()
            async let summary = homeService.summary()
            async let groupsList = groupsService.myGroups()
            async let groupBalances = groupsService.myBalanceAcrossGroups()
            async let members = groupsService.myGroupMemberships()
            async let activity = activityService.recent(limit: 10)
            async let friendBalances = friendsService.balances()

            let (p, s, gs, gbs, mems, acts, fbs) = try await (
                profile, summary, groupsList, groupBalances, members, activity, friendBalances
            )

            firstName = p.fullName?.components(separatedBy: " ").first
                ?? p.username
                ?? "there"

            let profileCurrency = p.defaultCurrency.uppercased()
            UserPreferences.defaultCurrency = profileCurrency
            landingCurrency = profileCurrency

            youOwe = s?.youOwe ?? 0
            youAreOwed = s?.youAreOwed ?? 0

            owedGroupsCount = gbs.filter { $0.balance != 0 }.count
            if let me = await SupabaseProvider.currentUserId() {
                owedFromCount = fbs.filter { $0.balance(for: me) > 0 }.count
            }

            let memberCountByGroup = Dictionary(grouping: mems, by: { $0.groupId })
                .mapValues(\.count)

            let myBalanceByGroup: [UUID: Decimal] = Dictionary(
                uniqueKeysWithValues: gbs.map { ($0.groupId, $0.balance) }
            )

            groups = gs.map {
                GroupRowItem(
                    id: $0.id,
                    name: $0.name,
                    memberCount: memberCountByGroup[$0.id] ?? 0,
                    yourBalance: myBalanceByGroup[$0.id] ?? 0,
                    currency: $0.defaultCurrency
                )
            }

            recentActivity = acts.map(makeActivityItem)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func makeActivityItem(_ a: ActivityDTO) -> ActivityItem {
        let title: String
        let subtitle: String
        switch a.kind {
        case .expenseCreated:    title = "New expense"; subtitle = "Added to a group"
        case .expenseUpdated:    title = "Expense updated"; subtitle = "Details changed"
        case .expenseDeleted:    title = "Expense removed"; subtitle = "Deleted from group"
        case .settlementCreated: title = "Settlement"; subtitle = "Someone settled up"
        case .groupCreated:      title = "New group"; subtitle = "You were added"
        case .memberAdded:       title = "Member added"; subtitle = "Group changed"
        case .memberRemoved:     title = "Member removed"; subtitle = "Group changed"
        case .friendshipAccepted:title = "New friend"; subtitle = "You're now connected"
        case .commentAdded:      title = "Comment"; subtitle = "New message on an expense"
        }
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
}
