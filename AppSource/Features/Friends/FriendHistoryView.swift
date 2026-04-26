//
//  FriendHistoryView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Per-friend transaction history. Reachable from the Friends list when the
//  user taps a friend tile. Shows running balance + the date-ordered ledger
//  of expenses and settlements between the current user and that friend
//  across every group, plus a primary "Add Expense" CTA that pre-targets the
//  same friend (which is the action the tap previously short-circuited to).
//

import SwiftUI

struct FriendHistoryView: View {
    let friend: FriendRowItem

    @State private var vm: FriendHistoryViewModel
    @State private var showAddExpense: Bool = false
    /// Active expense being edited from a tapped ledger row. Settlements
    /// are not editable — only entries with `kind == .expense` populate
    /// this binding.
    @State private var editingExpense: ExpenseDTO?
    /// Per-row busy flag while we fetch the full `ExpenseDTO` from the
    /// row's `entryId`, so the user gets feedback on tap.
    @State private var loadingExpenseId: UUID?
    @Environment(\.dismiss) private var dismiss

    init(friend: FriendRowItem) {
        self.friend = friend
        self._vm = State(initialValue: FriendHistoryViewModel(friend: friend))
    }

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    navBar
                    header
                    balanceCard

                    if vm.isLoading && vm.entries.isEmpty {
                        ProgressView()
                            .tint(AppColor.pandaBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if vm.entries.isEmpty {
                        emptyCard
                    } else {
                        sectionHeader
                        ledger
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
            .refreshable { await vm.load() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryButton(title: "Add Expense") { showAddExpense = true }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(AppColor.bgTop)
            }
        }
        .task { await vm.load() }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showAddExpense, onDismiss: {
            Task { await vm.load() }
        }) {
            AddExpenseView(preselectedFriend: friend)
        }
        .fullScreenCover(item: $editingExpense, onDismiss: {
            Task { await vm.load() }
        }) { expense in
            AddExpenseView(editingExpense: expense, friendHint: friend)
        }
    }

    /// Resolves the full `ExpenseDTO` for a tapped ledger row and presents
    /// the editor. Settlement rows are silently ignored.
    private func openEditor(for entry: FriendLedgerEntryDTO) {
        guard entry.kind == .expense else { return }
        guard loadingExpenseId == nil else { return }
        loadingExpenseId = entry.id
        Task {
            defer { loadingExpenseId = nil }
            do {
                let dto = try await ExpensesService.shared.fetch(id: entry.id)
                editingExpense = dto
            } catch {
                vm.errorMessage = AppError.wrap(error).errorDescription
            }
        }
    }

    // MARK: - Sections

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

            Text("History")
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(friend.avatarTint.opacity(0.5))
                    .frame(width: 64, height: 64)
                Text(String(friend.name.prefix(1)))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
            }
            Text(friend.name)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Text("\(vm.entries.count) entries")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var balanceCard: some View {
        let amountText: String = {
            if vm.isSettled { return Decimal(0).currencyString(code: vm.currency) }
            let magnitude = (vm.balance < 0 ? -vm.balance : vm.balance)
                .currencyString(code: vm.currency)
            return vm.balance > 0 ? "+\(magnitude)" : "-\(magnitude)"
        }()

        let label: String = {
            if vm.balance > 0 { return "\(friend.name) owes you" }
            if vm.balance < 0 { return "You owe \(friend.name)" }
            return "All settled"
        }()

        let color: Color = {
            if vm.balance > 0 { return AppColor.positive }
            if vm.balance < 0 { return AppColor.negative }
            return AppColor.textSecondary
        }()

        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Text(amountText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            Spacer()
            Image(systemName: vm.isSettled ? "checkmark.seal.fill" : "arrow.left.arrow.right")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColor.pandaBlue)
                .frame(width: 44, height: 44)
                .background(Circle().fill(AppColor.chipBlue))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }

    private var sectionHeader: some View {
        HStack {
            Text("Transactions")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text("\(vm.entries.count)")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.top, 4)
    }

    private var ledger: some View {
        VStack(spacing: 10) {
            ForEach(vm.entries) { row in
                Button {
                    openEditor(for: row)
                } label: {
                    FriendLedgerRow(
                        entry: row,
                        friendName: friend.name,
                        isLoading: loadingExpenseId == row.id
                    )
                }
                .buttonStyle(.plain)
                .disabled(row.kind != .expense)
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
            Text("No shared transactions yet")
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
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

// MARK: - Row

private struct FriendLedgerRow: View {
    let entry: FriendLedgerEntryDTO
    let friendName: String
    /// Optional spinner shown over the trailing amount block while we
    /// resolve the full ExpenseDTO before opening the editor.
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.chipBlue)
                    .frame(width: 44, height: 44)
                Text(iconText)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(AppColor.pandaBlue)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(deltaText)
                        .font(AppFont.amountSmall)
                        .foregroundStyle(deltaColor)
                    Text(entry.amount.currencyString(code: entry.currency))
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }

    private var iconText: String {
        if entry.kind == .settlement { return "✅" }
        if let e = entry.emoji, !e.isEmpty { return e }
        return "💸"
    }

    private var subtitle: String {
        let date = RelativeDateFormatters.short(fromISODay: entry.occurredOn)
        let payerLabel = entry.iPaid ? "You paid" : "\(friendName) paid"
        let groupSuffix = entry.groupName.map { " · \($0)" } ?? ""
        switch entry.kind {
        case .expense:
            return "\(payerLabel) · \(date)\(groupSuffix)"
        case .settlement:
            let direction = entry.iPaid ? "You settled" : "\(friendName) settled"
            return "\(direction) · \(date)\(groupSuffix)"
        }
    }

    private var deltaText: String {
        if entry.myShare == 0 { return Decimal(0).currencyString(code: entry.currency) }
        let magnitude = (entry.myShare < 0 ? -entry.myShare : entry.myShare)
            .currencyString(code: entry.currency)
        return entry.myShare > 0 ? "+\(magnitude)" : "-\(magnitude)"
    }

    private var deltaColor: Color {
        if entry.myShare > 0 { return AppColor.positive }
        if entry.myShare < 0 { return AppColor.negative }
        return AppColor.textSecondary
    }
}
