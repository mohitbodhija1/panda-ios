//
//  AccountViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Drives the Account screen in Settings: lets the signed-in user edit
//  their display name and profile photo. The current avatar URL is
//  fetched on load and re-synced whenever the user picks a new photo so
//  the preview reflects what's actually stored on Supabase.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@Observable
@MainActor
final class AccountViewModel {
    /// Editable form fields. Bound by the view; never written directly by
    /// network calls so user input is preserved during background loads.
    var fullName: String = ""

    /// Locally selected image data (from PhotosPicker). Non-nil while the
    /// user has an unsaved selection; cleared after a successful save.
    var pendingAvatarData: Data?

    /// URL of the currently persisted avatar (if any). Source of truth for
    /// the preview when no pending selection exists.
    var savedAvatarUrl: String?

    /// Email/username are shown read-only on the screen for context.
    var email: String?
    var username: String?

    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String?
    var didSaveAt: Date?

    private let profiles = ProfilesService.shared
    private var initialFullName: String = ""

    var canSave: Bool {
        guard !isSaving else { return false }
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameChanged = trimmed != initialFullName
        let avatarChanged = pendingAvatarData != nil
        return !trimmed.isEmpty && (nameChanged || avatarChanged)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me = try await profiles.me()
            applyServerProfile(me)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    /// Loads the bytes from a PhotosPicker selection into `pendingAvatarData`
    /// so the preview updates instantly. Errors are surfaced via
    /// `errorMessage`; the user can retry without leaving the screen.
    func setPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            pendingAvatarData = nil
            return
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                pendingAvatarData = data
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    /// Persists name + avatar. Returns true on success so the caller can
    /// pop the screen / show a confirmation chip.
    @discardableResult
    func save() async -> Bool {
        guard canSave else { return false }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            // Upload first so we never patch a stale name only to fail on
            // the avatar leg and leave the user in an inconsistent state.
            var nextAvatarUrl: String? = savedAvatarUrl
            if let data = pendingAvatarData {
                nextAvatarUrl = try await profiles.uploadAvatar(data: data)
            }

            let updated = try await profiles.updateMe(
                fullName: trimmedName,
                username: nil,
                avatarUrl: nextAvatarUrl
            )

            applyServerProfile(updated)
            pendingAvatarData = nil
            didSaveAt = Date()
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }

    private func applyServerProfile(_ p: ProfileDTO) {
        fullName = p.fullName ?? ""
        initialFullName = fullName
        savedAvatarUrl = p.avatarUrl
        email = p.email
        username = p.username
    }
}
