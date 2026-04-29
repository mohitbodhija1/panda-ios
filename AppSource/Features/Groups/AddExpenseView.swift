//
//  AddExpenseView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Global "Add Expense" surface presented as a full-screen cover from the
//  tab-bar FAB and also reachable from inside a group / a friend row. A
//  Group/Friends segmented control at the top lets the user pick the target;
//  it is hidden when the entry point pinned a single target.
//

import SwiftUI

struct AddExpenseView: View {
    @State private var vm: AddExpenseViewModel
    @State private var showGroupPicker: Bool = false
    @State private var showFriendPicker: Bool = false
    @State private var showSplitMembersPicker: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(preselectedGroup: GroupRowItem? = nil, preselectedFriend: FriendRowItem? = nil) {
        self._vm = State(initialValue: AddExpenseViewModel(
            preselectedGroup: preselectedGroup,
            preselectedFriend: preselectedFriend
        ))
    }

    /// Edit-mode initializer. Pre-fills the form from the existing expense
    /// and routes save through `rpc_update_expense`.
    init(editingExpense: ExpenseDTO,
         friendHint: FriendRowItem? = nil,
         groupHint: GroupRowItem? = nil)
    {
        self._vm = State(initialValue: AddExpenseViewModel(
            editingExpense: editingExpense,
            friendHint: friendHint,
            groupHint: groupHint
        ))
    }

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    navBar

                    Text(headerSubtitle)
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    if !vm.isModeLocked {
                        ExpenseTargetSegmented(
                            selection: Binding(
                                get: { vm.mode },
                                set: { vm.didChangeMode(to: $0) }
                            )
                        )
                    }

                    TintedFormCard {
                        targetRow

                        TintedFormRowField(
                            icon: "note.text",
                            tint: AppColor.avatarTintE,
                            title: "Title",
                            placeholder: "Dinner at Joe's",
                            text: Binding(get: { vm.title }, set: { vm.title = $0 }),
                            autocap: .words
                        )
                        TintedFormRowField(
                            icon: "face.smiling",
                            tint: AppColor.avatarTintC,
                            title: "Emoji",
                            placeholder: "💸",
                            text: Binding(get: { vm.emoji }, set: { vm.emoji = String($0.prefix(2)) }),
                            autocap: .never
                        )
                        CurrencyPickerRow(
                            icon: "dollarsign.circle",
                            tint: AppColor.avatarPink,
                            title: "Currency",
                            code: Binding(get: { vm.currency }, set: { vm.currency = $0 })
                        )
                        TintedFormRowField(
                            icon: "banknote.fill",
                            tint: AppColor.avatarPink,
                            title: "Amount (\(vm.currency))",
                            placeholder: "0.00",
                            text: Binding(get: { vm.amountText }, set: {
                                vm.amountText = $0
                                vm.handleAmountChanged()
                            }),
                            keyboard: .decimalPad,
                            autocap: .never
                        )
                        if vm.mode == .friends && !vm.isEditing {
                            TintedFormRowField(
                                icon: "person.fill",
                                tint: AppColor.avatarTintD,
                                title: "Your Share (\(vm.currency))",
                                placeholder: "0.00",
                                text: Binding(get: { vm.myShareText }, set: {
                                    vm.myShareText = $0
                                    vm.handleMyShareChanged()
                                }),
                                keyboard: .decimalPad,
                                autocap: .never
                            )
                            TintedFormRowField(
                                icon: "person.2.fill",
                                tint: AppColor.avatarTintE,
                                title: "Friend Share (\(vm.currency))",
                                placeholder: "0.00",
                                text: Binding(get: { vm.friendShareText }, set: {
                                    vm.friendShareText = $0
                                    vm.handleFriendShareChanged()
                                }),
                                keyboard: .decimalPad,
                                autocap: .never
                            )
                        }
                        if vm.mode == .group && !vm.isEditing {
                            Button { showSplitMembersPicker = true } label: {
                                TintedFormRow(
                                    icon: "person.3.fill",
                                    tint: AppColor.avatarGreen,
                                    title: "Split Between",
                                    value: splitLabel,
                                    isPlaceholder: splitIsPlaceholder,
                                    trailingChevron: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            TintedFormRow(
                                icon: "person.3.fill",
                                tint: AppColor.avatarGreen,
                                title: "Split Between",
                                value: splitLabel,
                                isPlaceholder: splitIsPlaceholder
                            )
                        }
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .scrollDismissesKeyboardForForms()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    PrimaryButton(title: vm.primaryActionTitle) {
                        Task {
                            if await vm.submit() {
                                NotificationCenter.default.post(name: .expenseDidMutate, object: nil)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!vm.canSubmit)
                    .opacity(vm.canSubmit ? 1 : 0.6)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [AppColor.bgTop.opacity(0), AppColor.bgTop],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        .offset(y: -24),
                        alignment: .top
                    )
                    .background(AppColor.bgTop)
                }
            }
        }
        .keyboardDismissToolbar()
        .task { await vm.load() }
        .onChange(of: vm.selectedGroupId) { _, _ in
            vm.syncCurrencyWithSelectedGroup()
            Task { await vm.loadMembers() }
        }
        .onChange(of: vm.selectedFriendId) { _, _ in
            vm.syncCurrencyWithSelectedFriend()
        }
        .confirmationDialog("Choose a group", isPresented: $showGroupPicker, titleVisibility: .visible) {
            ForEach(vm.availableGroups) { g in
                Button(g.name) { vm.selectedGroupId = g.id }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Choose a friend", isPresented: $showFriendPicker, titleVisibility: .visible) {
            ForEach(vm.availableFriends) { f in
                Button(f.isPending ? "\(f.name) · invite pending" : f.name) {
                    vm.selectedFriendId = f.id
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showSplitMembersPicker) {
            splitMembersSheet
                .presentationDetents([.large])
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var targetRow: some View {
        switch vm.mode {
        case .group:
            if let pinned = vm.preselectedGroup {
                TintedFormRow(
                    icon: "person.2.fill",
                    tint: AppColor.chipBlue,
                    title: "Group",
                    value: pinned.name,
                    isPlaceholder: false,
                    trailingChevron: false
                )
            } else {
                Button { showGroupPicker = true } label: {
                    TintedFormRow(
                        icon: "person.2.fill",
                        tint: AppColor.chipBlue,
                        title: "Group",
                        value: vm.selectedGroup?.name ?? "Select a group",
                        isPlaceholder: vm.selectedGroup == nil,
                        trailingChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        case .friends:
            if let pinned = vm.preselectedFriend {
                TintedFormRow(
                    icon: "person.fill",
                    tint: AppColor.chipBlue,
                    title: "With",
                    value: pinned.isPending ? "\(pinned.name) · invite pending" : pinned.name,
                    isPlaceholder: false,
                    trailingChevron: false
                )
            } else {
                Button { showFriendPicker = true } label: {
                    TintedFormRow(
                        icon: "person.fill",
                        tint: AppColor.chipBlue,
                        title: "Friend",
                        value: friendRowValue,
                        isPlaceholder: vm.selectedFriend == nil,
                        trailingChevron: true
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.availableFriends.isEmpty)
            }
        }
    }

    private var friendRowValue: String {
        if let f = vm.selectedFriend {
            return f.isPending ? "\(f.name) · invite pending" : f.name
        }
        return vm.availableFriends.isEmpty ? "No friends yet" : "Select a friend"
    }

    private var splitLabel: String {
        switch vm.mode {
        case .friends:
            guard vm.selectedFriend != nil else { return "Pick a friend" }
            if let mine = vm.parsedMyShare, let theirs = vm.parsedFriendShare {
                let mineText = NSDecimalNumber(decimal: mine).stringValue
                let theirText = NSDecimalNumber(decimal: theirs).stringValue
                return "You \(mineText) • Friend \(theirText)"
            }
            return "Enter both shares"
        case .group:
            if vm.groupMembers.isEmpty { return "No members" }
            let selectedCount = vm.selectedGroupMemberIds.count
            let total = vm.groupMembers.count
            if selectedCount == 0 { return "No members selected" }
            if selectedCount == total {
                return "\(total) " + (total == 1 ? "person" : "people") + " (equal)"
            }
            return "\(selectedCount) of \(total) selected"
        }
    }

    private var splitIsPlaceholder: Bool {
        switch vm.mode {
        case .friends: return vm.selectedFriend == nil || !vm.isFriendSplitValid
        case .group:   return vm.groupMembers.isEmpty || vm.selectedGroupMemberIds.isEmpty
        }
    }

    private var headerSubtitle: String {
        if vm.isEditing {
            return "Update the title, amount, or other\ndetails for this expense."
        }
        switch vm.mode {
        case .friends:
            return "Add expense details and split equally\nwith your friend."
        case .group:
            return "Add expense details and split\nequally with the group."
        }
    }

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppColor.cardHairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(vm.screenTitle)
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }

    private var splitMembersSheet: some View {
        NavigationStack {
            ZStack {
                AppColor.bgTop.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Button("Select All") { vm.selectAllGroupMembers() }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColor.pandaBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AppColor.chipBlue))

                            Button("Clear") { vm.clearSelectedGroupMembers() }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColor.negative)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AppColor.negative.opacity(0.12)))

                            Spacer()
                        }

                        VStack(spacing: 10) {
                            ForEach(vm.groupMembers, id: \.id) { member in
                                Button {
                                    vm.toggleGroupMember(member.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(AppColor.tint(for: member.id).opacity(0.28))
                                                .frame(width: 36, height: 36)
                                            Text(String(member.displayName.prefix(1)))
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(AppColor.textPrimary)
                                        }

                                        Text(member.displayName)
                                            .font(AppFont.rowTitle)
                                            .foregroundStyle(AppColor.textPrimary)

                                        Spacer()

                                        Image(systemName: vm.isGroupMemberSelected(member.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(vm.isGroupMemberSelected(member.id) ? AppColor.pandaBlue : AppColor.textSecondary.opacity(0.45))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(AppColor.cardHairline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Split Between")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSplitMembersPicker = false }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.pandaBlue)
                }
            }
        }
    }
}
