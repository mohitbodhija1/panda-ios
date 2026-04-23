//
//  ExpensesService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

struct CreateExpenseInput: Encodable {
    struct Split: Encodable {
        let user_id: UUID
        var amount_owed: Decimal? = nil
        var share_percent: Decimal? = nil
        var share_count: Int? = nil
    }
    let group_id: UUID?
    let title: String
    let notes: String?
    let emoji: String?
    let category_id: Int?
    let amount: Decimal
    let currency: String
    let paid_by: UUID
    let expense_date: String
    let split_type: SplitType
    let splits: [Split]
}

@MainActor
final class ExpensesService {
    static let shared = ExpensesService()

    private var db: PostgrestClient { SupabaseProvider.db }

    func list(groupId: UUID, limit: Int = 50) async throws -> [ExpenseDTO] {
        try await db.from("expenses")
            .select()
            .eq("group_id", value: groupId)
            .is("deleted_at", value: nil)
            .order("expense_date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func splits(for expenseId: UUID) async throws -> [ExpenseSplitDTO] {
        try await db.from("expense_splits")
            .select()
            .eq("expense_id", value: expenseId)
            .execute()
            .value
    }

    func create(_ input: CreateExpenseInput) async throws -> ExpenseDTO {
        struct Wrapper: Encodable { let payload: CreateExpenseInput }
        return try await db.rpc("rpc_create_expense", params: Wrapper(payload: input))
            .single()
            .execute()
            .value
    }

    func softDelete(_ expenseId: UUID) async throws {
        try await db.from("expenses")
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: expenseId)
            .execute()
    }
}
