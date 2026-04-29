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

    /// Lookup maps used by the view to resolve activity tap targets without
    /// re-fetching anything.
    private(set) var groupsById: [UUID: GroupRowItem] = [:]
    private(set) var friendsById: [UUID: FriendRowItem] = [:]

    private let profiles = ProfilesService.shared
    private let groupsService = GroupsService.shared
    private let friendsService = FriendsService.shared
    private let homeService = HomeService.shared
    private let activityService = ActivityService.shared

    func load() async {
        if isLoading { return }
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
            async let friendsWithBalances = friendsService.friendsWithBalances(status: .accepted)

            let (p, s, gs, gbs, mems, acts, fwbs) = try await (
                profile, summary, groupsList, groupBalances, members, activity, friendsWithBalances
            )

            firstName = p.fullName?.components(separatedBy: " ").first
                ?? p.username
                ?? "there"

            let profileCurrency = p.defaultCurrency.uppercased()
            UserPreferences.defaultCurrency = profileCurrency
            landingCurrency = profileCurrency

            youOwe = s?.youOwe ?? 0
            youAreOwed = s?.youAreOwed ?? 0

            owedGroupsCount = gbs.filter { $0.balance < 0 }.count
            let me = await SupabaseProvider.currentUserId()
            owedFromCount = fwbs.filter { $0.netOwed > 0 }.count

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
                    currency: $0.defaultCurrency,
                    avatarKey: $0.avatarUrl
                )
            }

            groupsById = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })

            friendsById = Dictionary(uniqueKeysWithValues: fwbs.map { (fb: FriendWithBalance) in
                (fb.profile.id, FriendRowItem(
                    id: fb.profile.id,
                    name: fb.profile.displayName,
                    avatarTint: AppColor.tint(for: fb.profile.id),
                    balance: fb.netOwed,
                    currency: fb.profile.defaultCurrency,
                    isPending: fb.isPending
                ))
            })

            let friendsByIdForBuilder = Dictionary(uniqueKeysWithValues: fwbs.map { ($0.profile.id, $0) })
            let groupsByIdForBuilder = Dictionary(uniqueKeysWithValues: gs.map { ($0.id, $0) })
            let context = ActivityItemBuilder.Context(
                me: me,
                friendsById: friendsByIdForBuilder,
                groupsById: groupsByIdForBuilder,
                fallbackCurrency: profileCurrency
            )
            recentActivity = acts.map { ActivityItemBuilder.make($0, in: context) }
        } catch is CancellationError {
            // Pull-to-refresh can cancel an in-flight load when a new one starts.
            // That's expected and should not show an error banner.
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
