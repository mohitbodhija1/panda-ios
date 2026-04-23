//
//  SettingsViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Drives user preferences that live on the profile row (authoritative) and
//  mirror locally via `UserPreferences` for instant reads. Default currency
//  is the first such preference; more can be added without touching the view.
//

import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var defaultCurrency: String = UserPreferences.defaultCurrency
    var isSaving: Bool = false
    var errorMessage: String?

    private let profiles = ProfilesService.shared

    func load() async {
        do {
            let me = try await profiles.me()
            let code = me.defaultCurrency.uppercased()
            defaultCurrency = code
            UserPreferences.defaultCurrency = code
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func setDefaultCurrency(_ code: String) async {
        let upper = code.uppercased()
        guard upper != defaultCurrency else { return }

        let previous = defaultCurrency
        defaultCurrency = upper
        UserPreferences.defaultCurrency = upper

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await profiles.updateDefaultCurrency(upper)
        } catch {
            // Roll back local mirror so UI and server stay consistent.
            defaultCurrency = previous
            UserPreferences.defaultCurrency = previous
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
