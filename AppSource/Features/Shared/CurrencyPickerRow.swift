//
//  CurrencyPickerRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Dropdown-style currency picker that matches the TintedFormRow chrome.
//  Loads the catalog from `currencies` (public read) and falls back to a
//  short static list if the fetch fails so the UI always renders.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class CurrencyCatalog {
    static let shared = CurrencyCatalog()

    var currencies: [CurrencyDTO] = CurrencyCatalog.fallback
    private(set) var hasLoaded = false

    private let service = CurrenciesService.shared

    func load(forceRefresh: Bool = false) async {
        if hasLoaded, !forceRefresh { return }
        do {
            let rows = try await service.list(forceRefresh: forceRefresh)
            if !rows.isEmpty { currencies = rows }
            hasLoaded = true
        } catch {
            // Stay on the fallback list; currencies shouldn't block the UI.
            hasLoaded = true
        }
    }

    func symbol(for code: String) -> String {
        currencies.first(where: { $0.code == code.uppercased() })?.symbol ?? code.uppercased()
    }

    /// Minimal offline list matching the initial `currencies` seed so the
    /// picker still works before the catalog is fetched or when offline.
    static let fallback: [CurrencyDTO] = [
        .init(code: "USD", name: "US Dollar",         symbol: "$",   decimals: 2),
        .init(code: "EUR", name: "Euro",              symbol: "€",   decimals: 2),
        .init(code: "GBP", name: "British Pound",     symbol: "£",   decimals: 2),
        .init(code: "INR", name: "Indian Rupee",      symbol: "₹",   decimals: 2),
        .init(code: "JPY", name: "Japanese Yen",      symbol: "¥",   decimals: 0),
        .init(code: "AUD", name: "Australian Dollar", symbol: "A$",  decimals: 2),
        .init(code: "CAD", name: "Canadian Dollar",   symbol: "C$",  decimals: 2),
        .init(code: "SGD", name: "Singapore Dollar",  symbol: "S$",  decimals: 2),
        .init(code: "AED", name: "UAE Dirham",        symbol: "د.إ", decimals: 2),
        .init(code: "CHF", name: "Swiss Franc",       symbol: "CHF", decimals: 2)
    ]
}

/// Dropdown row that fits inside a `TintedFormCard`.
struct CurrencyPickerRow: View {
    let icon: String
    let tint: Color
    let title: String
    @Binding var code: String
    var onSelect: ((String) -> Void)? = nil

    @State private var catalog = CurrencyCatalog.shared

    var body: some View {
        Menu {
            ForEach(catalog.currencies) { currency in
                Button {
                    code = currency.code
                    onSelect?(currency.code)
                } label: {
                    HStack {
                        Text("\(currency.code) · \(currency.name)")
                        if currency.code == code { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            TintedFormRow(
                icon: icon,
                tint: tint,
                title: title,
                value: displayValue,
                isPlaceholder: false,
                trailingChevron: true
            )
        }
        .buttonStyle(.plain)
        .task { await catalog.load() }
    }

    private var displayValue: String {
        let upper = code.uppercased()
        let symbol = catalog.symbol(for: upper)
        return symbol == upper ? upper : "\(upper) · \(symbol)"
    }
}
