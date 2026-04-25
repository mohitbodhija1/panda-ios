//
//  FriendsMultiPickerSheet.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Reusable bottom sheet that lets the user multi-select from their accepted
//  friends. Used by:
//    - AddGroupView      → seed the new group's `selectedMemberIds`
//    - GroupDetailView   → invite additional members into an existing group
//    - GroupSettingsSheet→ "Invite Members" entry
//
//  The sheet owns its own staging selection so callers only see the result
//  when "Done" is tapped (cancel / swipe-down discards). Already-member ids
//  can be passed via `disabledIds` to grey them out and prevent re-selection.
//

import SwiftUI

struct FriendsMultiPickerSheet: View {
    let title: String
    let confirmTitle: String
    let disabledIds: Set<UUID>
    let onConfirm: (Set<UUID>) -> Void

    @State private var friends: [FriendRowItem] = []
    @State private var staged: Set<UUID> = []
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    init(
        title: String = "Add Friends",
        confirmTitle: String = "Done",
        initialSelection: Set<UUID> = [],
        disabledIds: Set<UUID> = [],
        onConfirm: @escaping (Set<UUID>) -> Void
    ) {
        self.title = title
        self.confirmTitle = confirmTitle
        self.disabledIds = disabledIds
        self.onConfirm = onConfirm
        _staged = State(initialValue: initialSelection)
    }

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            VStack(spacing: 14) {
                grabber
                header

                SearchBar(placeholder: "Search friends", text: $query)
                    .padding(.horizontal, 20)

                if isLoading && friends.isEmpty {
                    ProgressView().tint(AppColor.pandaBlue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filtered.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { row(for: $0) }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }

                if let message = errorMessage {
                    Text(message)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.negative)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 6)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryButton(title: confirmLabel) {
                    onConfirm(staged)
                    dismiss()
                }
                .opacity(staged.isEmpty ? 0.6 : 1)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppColor.bgTop)
            }
        }
        .task { await load() }
    }

    private var confirmLabel: String {
        let n = staged.count
        return n == 0 ? confirmTitle : "\(confirmTitle) (\(n))"
    }

    private var filtered: [FriendRowItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return friends }
        return friends.filter { $0.name.lowercased().contains(q) }
    }

    private var grabber: some View {
        Capsule()
            .fill(AppColor.cardHairline)
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            Text(title)
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func row(for friend: FriendRowItem) -> some View {
        let isDisabled = disabledIds.contains(friend.id)
        let isSelected = staged.contains(friend.id)

        Button {
            guard !isDisabled else { return }
            if isSelected { staged.remove(friend.id) } else { staged.insert(friend.id) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(friend.avatarTint.opacity(0.5))
                        .frame(width: 40, height: 40)
                    Text(String(friend.name.prefix(1)))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    if isDisabled {
                        Text("Already in group")
                            .font(AppFont.rowSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: checkSymbol(isDisabled: isDisabled, isSelected: isSelected))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(checkColor(isDisabled: isDisabled, isSelected: isSelected))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColor.cardHairline, lineWidth: 1)
            )
            .opacity(isDisabled ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func checkSymbol(isDisabled: Bool, isSelected: Bool) -> String {
        if isDisabled { return "checkmark.circle.fill" }
        return isSelected ? "checkmark.circle.fill" : "circle"
    }

    private func checkColor(isDisabled: Bool, isSelected: Bool) -> Color {
        if isDisabled { return AppColor.textSecondary }
        return isSelected ? AppColor.pandaBlue : AppColor.cardHairline
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
            Text(query.isEmpty
                 ? "No friends to add yet."
                 : "No friends match \"\(query)\".")
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let rows = try await FriendsService.shared.friendsWithBalances(status: .accepted)
            friends = rows.map {
                FriendRowItem(
                    id: $0.profile.id,
                    name: $0.profile.displayName,
                    avatarTint: AppColor.tint(for: $0.profile.id),
                    balance: $0.netOwed,
                    currency: $0.profile.defaultCurrency,
                    isPending: $0.isPending
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
