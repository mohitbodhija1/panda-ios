//
//  SettlementsService.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation
import Supabase

struct SettleUpInput: Encodable {
    let group_id: UUID?
    let payer_id: UUID
    let payee_id: UUID
    let amount: Decimal
    let currency: String
    let method: SettlementMethod
    let note: String?
}

@MainActor
final class SettlementsService {
    static let shared = SettlementsService()

    private var db: PostgrestClient { SupabaseProvider.db }

    func list(groupId: UUID) async throws -> [SettlementDTO] {
        try await db.from("settlements")
            .select()
            .eq("group_id", value: groupId)
            .order("settled_at", ascending: false)
            .execute()
            .value
    }

    func settle(_ input: SettleUpInput) async throws -> SettlementDTO {
        struct Wrapper: Encodable { let payload: SettleUpInput }
        return try await db.rpc("rpc_settle_up", params: Wrapper(payload: input))
            .single()
            .execute()
            .value
    }
}
