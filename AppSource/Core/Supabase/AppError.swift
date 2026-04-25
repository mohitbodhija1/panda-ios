//
//  AppError.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Top-level error type the UI layer can switch on without leaking
//  Postgrest / Auth specifics.
//

import Foundation
import Supabase

enum AppError: Error, LocalizedError {
    case notAuthenticated
    case notFound
    case accountDeletionFailed(Int)
    case validation(String)
    case server(String)
    case network(URLError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:    return "You need to sign in to do that."
        case .notFound:            return "Not found."
        case .accountDeletionFailed(let code):
            return "Could not delete your account (error \(code)). Try again or contact support."
        case .validation(let m):   return m
        case .server(let m):       return m
        case .network(let e):      return e.localizedDescription
        case .unknown(let e):      return e.localizedDescription
        }
    }

    static func wrap(_ error: Error) -> AppError {
        if let app = error as? AppError { return app }
        if let url = error as? URLError { return .network(url) }
        if let pg = error as? PostgrestError {
            return wrapPostgrest(pg)
        }
        return .unknown(error)
    }

    /// Maps Postgres / PostgREST errors so expense and RPC failures are easier to interpret.
    /// Surfaces Postgres `message`, `detail`, `hint`, and `code` so we can tell which
    /// row / table / policy actually rejected the write (instead of a generic message).
    private static func wrapPostgrest(_ pg: PostgrestError) -> AppError {
        let msg = pg.message
        let lower = msg.lowercased()

        let combined = [msg, pg.detail, pg.hint]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " — ")

        if pg.code == "42501" || lower.contains("row-level security") {
            let codeTag = pg.code.map { " [pg \($0)]" } ?? ""
            let body = combined.isEmpty ? "Permission denied by the database." : combined
            let hint =
                " Make sure migrations through 20260425220000_rpc_create_expense_security_definer.sql are applied (`supabase db push`)."
            return .server(body + codeTag + hint)
        }

        // Check constraint / deferred trigger on expense_splits (sum, two-party rules, etc.).
        if pg.code == "23514"
            || lower.contains("splits sum")
            || lower.contains("paid_by user must")
            || lower.contains("must have exactly 2 participants")
        {
            return .validation(combined.isEmpty ? msg : combined)
        }

        if pg.code == "P0001" {
            return .validation(combined.isEmpty ? msg : combined)
        }

        return .server(combined.isEmpty ? msg : combined)
    }
}
