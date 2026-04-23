//
//  CurrencyGlyph.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Maps ISO 4217 codes to SF Symbols for compact currency affordances.
//

import Foundation

enum CurrencyGlyph {
    /// SF Symbol name for the given currency; falls back to `dollarsign.circle.fill`.
    static func sfSymbolName(for code: String) -> String {
        switch code.uppercased() {
        case "EUR": return "eurosign.circle.fill"
        case "GBP": return "sterlingsign.circle.fill"
        case "JPY", "CNY": return "yensign.circle.fill"
        case "INR": return "indianrupeesign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        case "TRY": return "turkishlirasign.circle.fill"
        case "RUB": return "rublesign.circle.fill"
        case "ILS": return "shekelsign.circle.fill"
        case "CHF": return "francsign.circle.fill"
        case "BRL": return "brazilianrealsign.circle.fill"
        case "MXN", "AUD", "CAD", "NZD", "SGD", "HKD", "USD", "ARS", "CLP", "COP":
            return "dollarsign.circle.fill"
        default:
            return "dollarsign.circle.fill"
        }
    }
}
