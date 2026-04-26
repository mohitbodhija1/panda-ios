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
                            text: Binding(get: { vm.amountText }, set: { vm.amountText = $0 }),
                            keyboard: .decimalPad,
                            autocap: .never
                        )
                        TintedFormRow(
                            icon: "person.3.fill",
                            tint: AppColor.avatarGreen,
                            title: "Split Between",
                            value: splitLabel,
                            isPlaceholder: splitIsPlaceholder
                        )
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
                            if await vm.submit() { dismiss() }
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
            return vm.selectedFriend == nil ? "Pick a friend" : "You + 1 friend (equal)"
        case .group:
            if vm.groupMembers.isEmpty { return "No members" }
            let count = vm.groupMembers.count
            return "\(count) " + (count == 1 ? "person" : "people") + " (equal)"
        }
    }

    private var splitIsPlaceholder: Bool {
        switch vm.mode {
        case .friends: return vm.selectedFriend == nil
        case .group:   return vm.groupMembers.isEmpty
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
}
