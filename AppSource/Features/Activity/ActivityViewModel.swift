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

    /// Lookup maps used by the view to resolve activity tap targets without
    /// re-fetching anything (mirrors HomeViewModel).
    private(set) var groupsById: [UUID: GroupRowItem] = [:]
    private(set) var friendsById: [UUID: FriendRowItem] = [:]

    private let activityService = ActivityService.shared
    private let groupsService = GroupsService.shared
    private let friendsService = FriendsService.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let rows = activityService.recent(limit: 100)
            async let gs = groupsService.myGroups()
            async let memberships = groupsService.myGroupMemberships()
            async let fwbs = friendsService.friendsWithBalances(status: .accepted)

            let (acts, gsList, mems, friendsList) = try await (rows, gs, memberships, fwbs)
            let me = await SupabaseProvider.currentUserId()

            let memberCountByGroup = Dictionary(grouping: mems, by: { $0.groupId })
                .mapValues(\.count)

            groupsById = Dictionary(uniqueKeysWithValues: gsList.map {
                ($0.id, GroupRowItem(
                    id: $0.id,
                    name: $0.name,
                    memberCount: memberCountByGroup[$0.id] ?? 0,
                    yourBalance: 0,
                    currency: $0.defaultCurrency
                ))
            })

            friendsById = Dictionary(uniqueKeysWithValues: friendsList.map { (fb: FriendWithBalance) in
                (fb.profile.id, FriendRowItem(
                    id: fb.profile.id,
                    name: fb.profile.displayName,
                    avatarTint: AppColor.tint(for: fb.profile.id),
                    balance: fb.netOwed,
                    currency: fb.profile.defaultCurrency,
                    isPending: fb.isPending
                ))
            })

            let friendsByIdForBuilder = Dictionary(uniqueKeysWithValues: friendsList.map { ($0.profile.id, $0) })
            let groupsByIdForBuilder = Dictionary(uniqueKeysWithValues: gsList.map { ($0.id, $0) })
            let context = ActivityItemBuilder.Context(
                me: me,
                friendsById: friendsByIdForBuilder,
                groupsById: groupsByIdForBuilder,
                fallbackCurrency: UserPreferences.defaultCurrency
            )
            feed = acts.map { ActivityItemBuilder.make($0, in: context) }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
