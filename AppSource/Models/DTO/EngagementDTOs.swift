//
//  EngagementDTOs.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Activity log, notifications, balance views.
//

import Foundation

enum ActivityKind: String, Codable, Hashable {
    case expenseCreated   = "expense_created"
    case expenseUpdated   = "expense_updated"
    case expenseDeleted   = "expense_deleted"
    case settlementCreated = "settlement_created"
    case groupCreated     = "group_created"
    case memberAdded      = "member_added"
    case memberRemoved    = "member_removed"
    case friendshipAccepted = "friendship_accepted"
    case commentAdded     = "comment_added"
}

struct ActivityDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID?
    let actorId: UUID
    let kind: ActivityKind
    let groupId: UUID?
    let expenseId: UUID?
    let settlementId: UUID?
    let payload: [String: AnyCodable]?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, kind, payload
        case userId = "user_id"
        case actorId = "actor_id"
        case groupId = "group_id"
        case expenseId = "expense_id"
        case settlementId = "settlement_id"
        case createdAt = "created_at"
    }
}

enum NotificationKind: String, Codable, Hashable {
    case expenseCreated   = "expense_created"
    case settlementCreated = "settlement_created"
    case friendInvite     = "friend_invite"
    case friendAccepted   = "friend_accepted"
    case commentAdded     = "comment_added"
    case recurringRun     = "recurring_run"
}

struct NotificationDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let kind: NotificationKind
    let title: String
    let body: String
    let payload: [String: AnyCodable]?
    let isRead: Bool
    let createdAt: Date
    let readAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, kind, title, body, payload
        case userId = "user_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case readAt = "read_at"
    }
}

struct GroupBalanceDTO: Codable, Hashable {
    let groupId: UUID
    let userId: UUID
    let currency: String
    let balance: Decimal

    enum CodingKeys: String, CodingKey {
        case currency, balance
        case groupId = "group_id"
        case userId = "user_id"
    }
}

struct FriendBalanceDTO: Codable, Hashable {
    let userA: UUID
    let userB: UUID
    let currency: String
    let netOwed: Decimal

    enum CodingKeys: String, CodingKey {
        case currency
        case userA = "user_a"
        case userB = "user_b"
        case netOwed = "net_owed"
    }

    func balance(for me: UUID) -> Decimal {
        me == userA ? netOwed : -netOwed
    }
}

struct HomeSummaryDTO: Codable, Hashable {
    let userId: UUID
    let youOwe: Decimal
    let youAreOwed: Decimal
    let net: Decimal
    let currency: String

    enum CodingKeys: String, CodingKey {
        case currency, net
        case userId = "user_id"
        case youOwe = "you_owe"
        case youAreOwed = "you_are_owed"
    }
}

/// Minimal type-erased Codable used for the activity / notification `payload` blobs.
struct AnyCodable: Codable, Hashable {
    let value: AnyHashable

    init(_ value: AnyHashable) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self.value = AnyHashable(Optional<String>.none as String? ?? "")
        } else if let b = try? c.decode(Bool.self) {
            self.value = AnyHashable(b)
        } else if let i = try? c.decode(Int.self) {
            self.value = AnyHashable(i)
        } else if let d = try? c.decode(Double.self) {
            self.value = AnyHashable(d)
        } else if let s = try? c.decode(String.self) {
            self.value = AnyHashable(s)
        } else if let a = try? c.decode([AnyCodable].self) {
            self.value = AnyHashable(a)
        } else if let o = try? c.decode([String: AnyCodable].self) {
            self.value = AnyHashable(o)
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool:    try c.encode(v)
        case let v as Int:     try c.encode(v)
        case let v as Double:  try c.encode(v)
        case let v as String:  try c.encode(v)
        case let v as [AnyCodable]: try c.encode(v)
        case let v as [String: AnyCodable]: try c.encode(v)
        default: try c.encodeNil()
        }
    }
}
