//
//  RowItems.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Thin display-layer view models consumed by row components. View models
//  project Supabase DTOs into these so the UI never imports `Supabase` or
//  touches snake_case columns.
//

import SwiftUI

struct GroupRowItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let memberCount: Int
    /// Positive → you're owed. Negative → you owe. Zero → settled.
    let yourBalance: Decimal
    let currency: String
}

struct FriendRowItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let avatarTint: Color
    /// Positive → they owe you. Negative → you owe them. Zero → settled.
    let balance: Decimal
    let currency: String
    /// True when the friendship request has not been accepted yet.
    var isPending: Bool = false
}

/// Row item for an out-of-band invite (email/phone) that has not been claimed
/// by a real account yet. We show it in the "Invited" section as informational
/// — there is no profile id to add expenses against.
struct PendingInviteRowItem: Identifiable, Hashable {
    let id: UUID
    let label: String
    let channel: FriendInviteChannel
    let avatarTint: Color
}

struct ExpenseRowItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let emoji: String
    let subtitle: String
    let amount: Decimal
    let currency: String
}

struct ActivityItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    /// Positive → you got paid / are owed, negative → you owe.
    let delta: Decimal
    let currency: String
    let dateLabel: String
    let avatarTint: Color
}

/// Lightweight formatters used by view models that assemble display items.
enum RelativeDateFormatters {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d"
        return f
    }()

    /// "Today", "Yesterday", or `MMM d`. Accepts ISO `yyyy-MM-dd` or `Date`.
    static func short(from date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return dayFormatter.string(from: date)
    }

    static func short(fromISODay iso: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: iso) else { return iso }
        return short(from: date)
    }
}
