//
//  ActivityItemBuilder.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Centralised mapping from `ActivityDTO` (raw v_recent_activity rows) to the
//  display-layer `ActivityItem` consumed by `ActivityRow`. Lives here so the
//  Home and Activity tabs render identical titles/subtitles/amounts and the
//  navigation ids (groupId / friendId) are computed in one place.
//

import Foundation
import SwiftUI

@MainActor
enum ActivityItemBuilder {
    struct Context {
        let me: UUID?
        /// Friends keyed by profile id; sourced from `FriendsService.friendsWithBalances(.accepted)`
        /// so we get a `displayName` that already handles email/phone fallbacks.
        let friendsById: [UUID: FriendWithBalance]
        let groupsById: [UUID: GroupDTO]
        let fallbackCurrency: String

        static let empty = Context(
            me: nil,
            friendsById: [:],
            groupsById: [:],
            fallbackCurrency: UserPreferences.defaultCurrency
        )
    }

    static func make(_ a: ActivityDTO, in context: Context) -> ActivityItem {
        let currency = a.currencyDisplayCode(fallback: context.fallbackCurrency)
        let dateLabel = RelativeDateFormatters.short(from: a.createdAt)
        let avatarTint = AppColor.tint(for: a.actorId)
        let actorName = displayName(for: a.actorId, in: context)
        let groupName = a.groupId.flatMap { context.groupsById[$0]?.name }

        switch a.kind {
        case .expenseCreated:
            return expenseItem(
                a,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                actorName: actorName,
                groupName: groupName,
                context: context
            )

        case .settlementCreated:
            return settlementItem(
                a,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                actorName: actorName,
                groupName: groupName,
                context: context
            )

        case .expenseUpdated:
            return ActivityItem(
                id: a.id,
                title: a.payloadTitle() ?? "Expense updated",
                subtitle: subtitle(prefix: "Updated by \(actorName)", suffix: dateLabel, group: groupName),
                delta: 0,
                amount: a.payloadAmount(),
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: a.groupId,
                friendId: a.counterpartyId
            )

        case .expenseDeleted:
            return ActivityItem(
                id: a.id,
                title: a.payloadTitle() ?? "Expense removed",
                subtitle: subtitle(prefix: "Removed by \(actorName)", suffix: dateLabel, group: groupName),
                delta: 0,
                amount: 0,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: a.groupId,
                friendId: a.counterpartyId
            )

        case .groupCreated:
            return ActivityItem(
                id: a.id,
                title: groupName.map { "New group · \($0)" } ?? "New group",
                subtitle: "\(actorName) created the group",
                delta: 0,
                amount: 0,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: a.groupId,
                friendId: nil
            )

        case .memberAdded:
            return ActivityItem(
                id: a.id,
                title: "Member added",
                subtitle: subtitle(prefix: "By \(actorName)", suffix: dateLabel, group: groupName),
                delta: 0,
                amount: 0,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: a.groupId,
                friendId: nil
            )

        case .memberRemoved:
            return ActivityItem(
                id: a.id,
                title: "Member removed",
                subtitle: subtitle(prefix: "By \(actorName)", suffix: dateLabel, group: groupName),
                delta: 0,
                amount: 0,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: a.groupId,
                friendId: nil
            )

        case .friendshipAccepted:
            let friendId = a.counterpartyId
            let friendName = friendId.flatMap { context.friendsById[$0]?.profile.displayName }
            return ActivityItem(
                id: a.id,
                title: "New friend",
                subtitle: friendName.map { "You're now connected with \($0)" } ?? "You're now connected",
                delta: 0,
                amount: 0,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: nil,
                friendId: friendId
            )

        case .commentAdded:
            return ActivityItem(
                id: a.id,
                title: "Comment",
                subtitle: subtitle(prefix: "From \(actorName)", suffix: dateLabel, group: groupName),
                delta: 0,
                amount: 0,
                currency: currency,
                dateLabel: dateLabel,
                avatarTint: avatarTint,
                groupId: a.groupId,
                friendId: a.counterpartyId
            )
        }
    }

    // MARK: - Specific kinds

    private static func expenseItem(
        _ a: ActivityDTO,
        currency: String,
        dateLabel: String,
        avatarTint: Color,
        actorName: String,
        groupName: String?,
        context: Context
    ) -> ActivityItem {
        let amount = a.payloadAmount()
        // Sign convention matches HomeHeroCard / FriendHistory: + means money
        // is coming TO me, − means I paid out. For expense_created we only
        // know the actor; if the actor is me, I paid (negative). Otherwise
        // someone else paid for something I'm a part of (likely positive).
        let isMe = (a.actorId == context.me)
        let delta: Decimal = (amount == 0)
            ? 0
            : (isMe ? -amount : amount)

        let payerLabel = isMe ? "You paid" : "\(actorName) paid"
        let title = a.payloadTitle() ?? "Expense"

        return ActivityItem(
            id: a.id,
            title: title,
            subtitle: subtitle(prefix: payerLabel, suffix: dateLabel, group: groupName),
            delta: delta,
            amount: amount,
            currency: currency,
            dateLabel: dateLabel,
            avatarTint: avatarTint,
            groupId: a.groupId,
            friendId: a.counterpartyId
        )
    }

    private static func settlementItem(
        _ a: ActivityDTO,
        currency: String,
        dateLabel: String,
        avatarTint: Color,
        actorName: String,
        groupName: String?,
        context: Context
    ) -> ActivityItem {
        let amount = a.payloadAmount()
        let payerId = a.payloadPayer()
        let payeeId = a.payloadPayee()
        let payerName = payerId.flatMap { displayName(for: $0, in: context) } ?? actorName
        let payeeName = payeeId.flatMap { displayName(for: $0, in: context) } ?? "someone"

        let delta: Decimal
        if let me = context.me, amount > 0 {
            if payeeId == me { delta = amount }
            else if payerId == me { delta = -amount }
            else { delta = 0 }
        } else {
            delta = 0
        }

        return ActivityItem(
            id: a.id,
            title: "Settlement",
            subtitle: subtitle(prefix: "\(payerName) → \(payeeName)", suffix: dateLabel, group: groupName),
            delta: delta,
            amount: amount,
            currency: currency,
            dateLabel: dateLabel,
            avatarTint: avatarTint,
            groupId: a.groupId,
            friendId: a.counterpartyId
        )
    }

    // MARK: - Helpers

    private static func displayName(for userId: UUID, in context: Context) -> String {
        if userId == context.me { return "You" }
        if let f = context.friendsById[userId] { return f.profile.displayName }
        return "Someone"
    }

    /// "<prefix> · <date>" with optional " · <group>" suffix.
    private static func subtitle(prefix: String, suffix: String, group: String?) -> String {
        var parts: [String] = [prefix, suffix]
        if let group, !group.isEmpty { parts.append(group) }
        return parts.joined(separator: " · ")
    }
}
