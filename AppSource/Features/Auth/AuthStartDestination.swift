//
//  AuthStartDestination.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Entry-point preference set by the onboarding flow and read by AuthFlowView
//  so that the CTA the user tapped determines which auth screen they land on.
//

import Foundation

enum AuthStartDestination: String, CaseIterable {
    case login
    case signUp

    static let storageKey = "pendingAuthStart"

    static var current: AuthStartDestination {
        guard
            let raw = UserDefaults.standard.string(forKey: storageKey),
            let value = AuthStartDestination(rawValue: raw)
        else {
            return .signUp
        }
        return value
    }

    static func set(_ destination: AuthStartDestination) {
        UserDefaults.standard.set(destination.rawValue, forKey: storageKey)
    }
}
