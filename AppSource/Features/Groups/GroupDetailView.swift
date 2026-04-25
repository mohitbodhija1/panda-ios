//
//  GroupDetailView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct GroupDetailView: View {
    let group: GroupRowItem

    @State private var vm: GroupDetailViewModel
    @State private var segment: GroupSegment = .expenses
    @State private var showAddExpense: Bool = false
    @State private var showAddMembers: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(group: GroupRowItem) {
        self.group = group
        self._vm = State(initialValue: GroupDetailViewModel(group: group))
    }

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    navBar

                    GroupHero()

                    GroupStatStrip(
                        totalExpenses: vm.totalExpenses,
                        youOwe: vm.youOwe,
                        youAreOwed: vm.youAreOwed,
                        currencyCode: group.currency
                    )

                    ExpensesSegmented(selection: $segment)

                    Group {
                        switch segment {
                        case .expenses: expensesList
                        case .balances: placeholder("Balances view coming soon")
                        case .members:  membersList
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
            .refreshable { await vm.load() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    PrimaryButton(title: "Add Expense") { showAddExpense = true }
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
        .task { await vm.load() }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showAddExpense, onDismiss: {
            Task { await vm.load() }
        }) {
            AddExpenseView(preselectedGroup: group)
        }
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

            VStack(spacing: 2) {
                Text(group.name)
                    .font(AppFont.navTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("\(memberCount) members")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }

    private var memberCount: Int {
        vm.members.isEmpty ? group.memberCount : vm.members.count
    }

    private var expensesList: some View {
        VStack(spacing: 10) {
            ForEach(vm.expenses) { ExpenseRow(expense: $0) }
            if vm.expenses.isEmpty && !vm.isLoading {
                placeholder("No expenses yet. Tap Add Expense to get started.")
            }
        }
    }

    private var membersList: some View {
        VStack(spacing: 10) {
            if vm.isOwner {
                Button { showAddMembers = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.pandaBlue)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(AppColor.chipBlue))
                        Text(vm.isAddingMembers ? "Adding…" : "Add Members")
                            .font(AppFont.rowTitle)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColor.textSecondary)
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
                .buttonStyle(.plain)
                .disabled(vm.isAddingMembers)
            }

            ForEach(vm.members) { memberRow($0) }

            if vm.members.isEmpty && !vm.isLoading {
                placeholder("No members yet.")
            }
        }
    }

    @ViewBuilder
    private func memberRow(_ member: GroupMemberRowItem) -> some View {
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

            if member.role == .owner {
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

    private func placeholder(_ text: String) -> some View {
        VStack {
            Text(text)
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        }
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
