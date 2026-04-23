//
//  IdentityDTOs.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Profiles, friendships, friend invites, device tokens.
//  Property names map 1:1 with Postgres columns; enable JSONDecoder
//  .convertFromSnakeCase or use CodingKeys explicitly when needed.
//

import Foundation

struct ProfileDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let username: String?
    let fullName: String?
    let email: String?
    let phone: String?
    let avatarUrl: String?
    let defaultCurrency: String
    let locale: String
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, username, email, phone, locale
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case defaultCurrency = "default_currency"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum FriendshipStatus: String, Codable, Hashable {
    case pending, accepted, blocked
}

struct FriendshipDTO: Codable, Hashable {
    let userA: UUID
    let userB: UUID
    let requestedBy: UUID
    let status: FriendshipStatus
    let createdAt: Date?
    let acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case status
        case userA = "user_a"
        case userB = "user_b"
        case requestedBy = "requested_by"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
    }

    func counterparty(of me: UUID) -> UUID { me == userA ? userB : userA }
}

enum FriendInviteChannel: String, Codable, Hashable {
    case email, phone
}

struct FriendInviteDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let inviterId: UUID
    let channel: FriendInviteChannel
    let email: String?
    let phone: String?
    let status: String
    let token: String
    let expiresAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, channel, email, phone, status, token
        case inviterId = "inviter_id"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

struct DeviceTokenDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let token: String
    let platform: String
    let lastSeenAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, token, platform
        case userId = "user_id"
        case lastSeenAt = "last_seen_at"
        case createdAt = "created_at"
    }
}
