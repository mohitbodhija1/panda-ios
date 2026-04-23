//
//  HomeView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @State private var showPaywall: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar

                    HomeHeroCard(
                        firstName: vm.firstName.isEmpty ? "there" : vm.firstName,
                        youOwe: vm.youOwe,
                        youAreOwed: vm.youAreOwed,
                        owedGroups: vm.owedGroupsCount,
                        owedFrom: vm.owedFromCount,
                        currencyCode: vm.landingCurrency
                    )

                    VStack(spacing: 10) {
                        SectionHeader(title: "Recent Activity")
                        if vm.recentActivity.isEmpty {
                            emptyCard("No activity yet. Create a group or add an expense to get started.")
                        } else {
                            ForEach(vm.recentActivity) { ActivityRow(activity: $0) }
                        }
                    }

                    VStack(spacing: 10) {
                        SectionHeader(title: "Your Groups")
                        if vm.groups.isEmpty {
                            emptyCard("You aren't in any groups yet.")
                        } else {
                            ForEach(vm.groups.prefix(1)) { HomeGroupRow(group: $0) }
                        }
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var topBar: some View {
        HStack {
            Button { showSettings = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            Text("Panda")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            HStack(spacing: 16) {
                Button { /* illustrative */ } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                }
                Button { showPaywall = true } label: {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.goldAccent)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(AppFont.bodyRegular)
            .foregroundStyle(AppColor.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
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
