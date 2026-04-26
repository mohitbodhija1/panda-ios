//
//  AccountView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Settings → Account: lets the signed-in user edit their display name
//  and profile photo. Avatar uploads land in the public `avatars` bucket
//  and the resulting URL is stored on `profiles.avatar_url` so every
//  surface (friends list, group members, hero card) refreshes on next load.
//

import PhotosUI
import SwiftUI

struct AccountView: View {
    @State private var vm = AccountViewModel()
    @State private var photoPickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("Update how friends see you across\ngroups and activity.")
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                        AccountAvatarPreview(
                            pendingData: vm.pendingAvatarData,
                            savedUrl: vm.savedAvatarUrl,
                            initials: initials(for: vm.fullName)
                        )
                    }
                    .buttonStyle(.plain)
                    .onChange(of: photoPickerItem) { _, newItem in
                        Task { await vm.setPickedPhoto(newItem) }
                    }

                    TintedFormCard {
                        TintedFormRowField(
                            icon: "person.fill",
                            tint: AppColor.chipBlue,
                            title: "Display Name",
                            placeholder: "Your name",
                            text: Binding(get: { vm.fullName }, set: { vm.fullName = $0 }),
                            autocap: .words
                        )

                        if let email = vm.email, !email.isEmpty {
                            TintedFormRow(
                                icon: "envelope.fill",
                                tint: AppColor.avatarTintE,
                                title: "Email",
                                value: email
                            )
                        }

                        if let username = vm.username, !username.isEmpty {
                            TintedFormRow(
                                icon: "at",
                                tint: AppColor.avatarTintD,
                                title: "Username",
                                value: "@\(username)"
                            )
                        }
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    if vm.didSaveAt != nil && vm.errorMessage == nil {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.positive)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboardForForms()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryButton(title: vm.isSaving ? "Saving…" : "Save Changes") {
                    Task { _ = await vm.save() }
                }
                .disabled(!vm.canSave)
                .opacity(vm.canSave ? 1 : 0.6)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(AppColor.bgTop)
            }
        }
        .keyboardDismissToolbar()
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if vm.fullName.isEmpty { await vm.load() }
        }
    }

    /// Two-letter initials for the avatar fallback when no photo exists.
    private func initials(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "?" }
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2,
           let first = parts.first?.first,
           let last = parts.last?.first {
            return String([first, last]).uppercased()
        }
        return String(trimmed.prefix(1)).uppercased()
    }
}

/// Circular avatar preview that prefers the locally picked image, then
/// the saved URL, and finally an initials fallback. The camera badge is
/// always rendered so the affordance is consistent with Add Friend / Add Group.
private struct AccountAvatarPreview: View {
    let pendingData: Data?
    let savedUrl: String?
    let initials: String

    private static let size: CGFloat = 92

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let pendingData, let ui = UIImage(data: pendingData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else if let url = remoteURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            initialsFallback
                                .overlay(ProgressView().tint(AppColor.pandaBlue))
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            initialsFallback
                        @unknown default:
                            initialsFallback
                        }
                    }
                } else {
                    initialsFallback
                }
            }
            .frame(width: Self.size, height: Self.size)
            .background(Circle().fill(AppColor.avatarTintE.opacity(0.55)))
            .clipShape(Circle())

            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppColor.pandaBlue))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 4, y: 4)
        }
    }

    private var remoteURL: URL? {
        guard let savedUrl, !savedUrl.isEmpty else { return nil }
        return URL(string: savedUrl)
    }

    private var initialsFallback: some View {
        Text(initials)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
