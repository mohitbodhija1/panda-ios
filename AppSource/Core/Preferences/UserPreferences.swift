//
//  UserPreferences.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Per user rules, only UI preferences live in `@AppStorage` / UserDefaults.
//  The authoritative value for each preference still lives on Supabase
//  (`profiles.default_currency`, etc.); this store exists so views can read
//  the latest value synchronously without re-querying the network on every
//  render, and so changes feel instant while the server write is in flight.
//

import Foundation
import SwiftUI

enum UserPreferences {
    enum Keys {
        static let defaultCurrency = "pandasplit.defaultCurrency"
    }

    static let fallbackCurrency = "USD"

    /// Synchronous read for non-SwiftUI call sites. Views should prefer the
    /// `@AppStorage` wrapper below for reactive updates.
    static var defaultCurrency: String {
        get { UserDefaults.standard.string(forKey: Keys.defaultCurrency) ?? fallbackCurrency }
        set { UserDefaults.standard.set(newValue.uppercased(), forKey: Keys.defaultCurrency) }
    }
}

/// Convenience wrapper for SwiftUI views:
/// `@AppStorage(UserPreferences.Keys.defaultCurrency) var code: String = UserPreferences.fallbackCurrency`
extension AppStorage where Value == String {
    init(defaultCurrency: Void) {
        self.init(wrappedValue: UserPreferences.fallbackCurrency, UserPreferences.Keys.defaultCurrency)
    }
}
