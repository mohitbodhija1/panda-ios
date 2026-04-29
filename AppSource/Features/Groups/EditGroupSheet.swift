//
//  EditGroupSheet.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Owner-only sheet that lets the group owner rename the group and curate
//  the member list. Reuses `GroupDetailViewModel` as the source of truth
//  so any rename / add / remove immediately reflects on the underlying
//  group detail screen without a manual refresh.
//

import SwiftUI

struct EditGroupSheet: View {
    @Bindable var vm: GroupDetailViewModel

    @State private var draftName: String = ""
    @State private var showAddMembers: Bool = false
    @State private var memberPendingRemoval: GroupMemberRowItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgTop.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Text("Update the group name and manage who's\npart of this group.")
                            .font(AppFont.bodyRegular)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)

                        TintedFormCard {
                            TintedFormRowField(
                                icon: "person.crop.circle",
                                tint: AppColor.chipBlue,
                                title: "Group Name",
                                placeholder: "Group name",
                                text: $draftName
                            )
                        }

                        membersSection

                        if let message = vm.errorMessage {
                            Text(message)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.negative)
                                .multilineTextAlignment(.center)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboardForForms()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    PrimaryButton(title: vm.isRenaming ? "Saving…" : "Save Changes") {
                        Task {
                            let renamed = await vm.rename(to: draftName)
                            if renamed || draftName.trimmingCharacters(in: .whitespacesAndNewlines) == vm.displayName {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.6)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(AppColor.bgTop)
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .keyboardDismissToolbar()
            .onAppear { draftName = vm.displayName }
            .sheet(isPresented: $showAddMembers) {
                FriendsMultiPickerSheet(
                    title: "Add Members",
                    confirmTitle: "Invite",
                    disabledIds: vm.memberIds
                ) { picked in
                    Task { await vm.addMembers(friendIds: picked) }
                }
                .presentationDetents([.large])
            }
            .confirmationDialog(
                "Remove \(memberPendingRemoval?.name ?? "member")?",
                isPresented: removalDialogBinding,
                titleVisibility: .visible
            ) {
                if let member = memberPendingRemoval {
                    Button("Remove", role: .destructive) {
                        Task { await vm.removeMember(member) }
                        memberPendingRemoval = nil
                    }
                    Button("Cancel", role: .cancel) {
                        memberPendingRemoval = nil
                    }
                }
            } message: {
                Text("They will lose access to this group's expenses.")
            }
        }
    }

    private var canSave: Bool {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !vm.isRenaming
    }

    private var removalDialogBinding: Binding<Bool> {
        Binding(
            get: { memberPendingRemoval != nil },
            set: { if !$0 { memberPendingRemoval = nil } }
        )
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Members")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { showAddMembers = true } label: {
                TintedFormRow(
                    icon: "person.crop.circle.badge.plus",
                    tint: AppColor.chipBlue,
                    title: vm.isAddingMembers ? "Adding…" : "Add Members",
                    value: "Invite friends to this group",
                    isPlaceholder: true,
                    trailingChevron: true
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.isAddingMembers)

            ForEach(vm.members) { member in
                memberRow(member)
            }
        }
    }

    @ViewBuilder
    private func memberRow(_ member: GroupMemberRowItem) -> some View {
        let isRemoving = vm.removingMemberIds.contains(member.id)
        let canRemove = !member.isCurrentUser && member.role != .owner

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(member.avatarTint.opacity(0.5))
                    .frame(width: 40, height: 40)
                Text(String(member.name.prefix(1)))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.isCurrentUser ? "\(member.name) (You)" : member.name)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(member.role == .owner ? "Owner" : "Member")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            if canRemove {
                Button {
                    memberPendingRemoval = member
                } label: {
                    if isRemoving {
                        ProgressView().tint(AppColor.negative)
                    } else {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColor.negative)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRemoving)
            } else if member.role == .owner {
                Text("Owner")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColor.chipBlue))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }
}
