//
//  AppError.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Top-level error type the UI layer can switch on without leaking
//  Postgrest / Auth specifics.
//

import Foundation

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
        return .unknown(error)
    }
}
