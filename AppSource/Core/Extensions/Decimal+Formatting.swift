//
//  Decimal+Formatting.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Shared currency formatting helpers used across rows, cards, and balance
//  widgets. Kept locale-aware but defaulted to USD so the UI looks consistent
//  while the multi-currency work is still in progress.
//

import Foundation

extension Decimal {
    /// `$1,234.56` style. Currency code is overridable (defaults to USD to
    /// match the design system used in the mocks).
    func currencyString(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "\(code) 0.00"
    }

    /// Uses the last-known profile default from `UserPreferences` (synced on Home load).
    var currencyString: String { currencyString(code: UserPreferences.defaultCurrency) }

    /// Signed `+$45.00` / `-$12.00` in the given ISO currency code.
    func signedCurrencyString(code: String) -> String {
        let magnitude = (self < 0 ? -self : self).currencyString(code: code)
        return self < 0 ? "-\(magnitude)" : "+\(magnitude)"
    }

    /// Signed amount using `UserPreferences.defaultCurrency`.
    var signedCurrencyString: String { signedCurrencyString(code: UserPreferences.defaultCurrency) }
}
