//
//  GroupDetailView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct GroupDetailView: View {
    let group: GroupRowItem

    @State private var vm: GroupDetailViewModel
    @State private var segment: GroupSegment = .expenses
    @State private var showSettings: Bool = false
    @State private var showAddExpense: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(group: GroupRowItem) {
        self.group = group
        self._vm = State(initialValue: GroupDetailViewModel(group: group))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    navBar

                    GroupHero()

                    GroupStatStrip(
                        totalExpenses: vm.totalExpenses,
                        youOwe: vm.youOwe,
                        youAreOwed: vm.youAreOwed
                    )

                    ExpensesSegmented(selection: $segment)

                    Group {
                        switch segment {
                        case .expenses: expensesList
                        case .balances: placeholder("Balances view coming soon")
                        case .members:  placeholder("Members view coming soon")
                        }
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .refreshable { await vm.load() }

            PrimaryButton(title: "Add Expense") { showAddExpense = true }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [AppColor.bgTop.opacity(0.0), AppColor.bgTop],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                    .offset(y: 20),
                    alignment: .top
                )
        }
        .task { await vm.load() }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            GroupSettingsSheet()
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showAddExpense, onDismiss: {
            Task { await vm.load() }
        }) {
            AddExpenseView(preselectedGroup: group)
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
                Text("\(group.memberCount) members")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppColor.cardHairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var expensesList: some View {
        VStack(spacing: 10) {
            ForEach(vm.expenses) { ExpenseRow(expense: $0) }
            if vm.expenses.isEmpty && !vm.isLoading {
                placeholder("No expenses yet. Tap Add Expense to get started.")
            }
        }
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
