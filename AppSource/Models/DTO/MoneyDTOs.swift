//
//  MoneyDTOs.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Currencies, categories, groups, expenses, splits, settlements, recurring.
//

import Foundation

struct CurrencyDTO: Codable, Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let symbol: String
    let decimals: Int
}

struct ExpenseCategoryDTO: Codable, Identifiable, Hashable {
    let id: Int
    let key: String
    let label: String
    let emoji: String
    let icon: String
    let isSystem: Bool

    enum CodingKeys: String, CodingKey {
        case id, key, label, emoji, icon
        case isSystem = "is_system"
    }
}

struct GroupDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let avatarUrl: String?
    let defaultCurrency: String
    let createdBy: UUID
    let isArchived: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case avatarUrl = "avatar_url"
        case defaultCurrency = "default_currency"
        case createdBy = "created_by"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum GroupMemberRole: String, Codable, Hashable {
    case owner, member
}

struct GroupMemberDTO: Codable, Hashable {
    let groupId: UUID
    let userId: UUID
    let role: GroupMemberRole
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case role
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

enum SplitType: String, Codable, Hashable {
    case equal, exact, percent, shares
}

struct ExpenseDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID?
    let title: String
    let notes: String?
    let emoji: String?
    let categoryId: Int?
    let amount: Decimal
    let currency: String
    let fxToGroupRate: Decimal?
    let paidBy: UUID
    let expenseDate: String   // ISO yyyy-MM-dd
    let splitType: SplitType
    let recurringId: UUID?
    let createdBy: UUID
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, notes, emoji, amount, currency
        case groupId = "group_id"
        case categoryId = "category_id"
        case fxToGroupRate = "fx_to_group_rate"
        case paidBy = "paid_by"
        case expenseDate = "expense_date"
        case splitType = "split_type"
        case recurringId = "recurring_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ExpenseSplitDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let expenseId: UUID
    let userId: UUID
    let amountOwed: Decimal
    let sharePercent: Decimal?
    let shareCount: Int?
    let isSettled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case expenseId = "expense_id"
        case userId = "user_id"
        case amountOwed = "amount_owed"
        case sharePercent = "share_percent"
        case shareCount = "share_count"
        case isSettled = "is_settled"
    }
}

enum SettlementMethod: String, Codable, Hashable {
    case cash, upi, venmo, paypal, in_app, other
}

struct SettlementDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID?
    let payerId: UUID
    let payeeId: UUID
    let amount: Decimal
    let currency: String
    let method: SettlementMethod
    let note: String?
    let settledAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, currency, method, note
        case groupId = "group_id"
        case payerId = "payer_id"
        case payeeId = "payee_id"
        case settledAt = "settled_at"
    }
}

struct RecurringExpenseDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID?
    let title: String
    let amount: Decimal
    let currency: String
    let paidBy: UUID
    let splitType: SplitType
    let frequency: String
    let intervalCount: Int
    let nextRunOn: String
    let lastRunOn: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, amount, currency, frequency
        case groupId = "group_id"
        case paidBy = "paid_by"
        case splitType = "split_type"
        case intervalCount = "interval_count"
        case nextRunOn = "next_run_on"
        case lastRunOn = "last_run_on"
        case isActive = "is_active"
    }
}
