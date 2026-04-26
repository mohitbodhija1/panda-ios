//
//  HomeView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct HomeView: View {
    /// Cap the Recent Activity preview shown on Home. Users can open the
    /// Activity tab for the full feed.
    static let recentActivityLimit: Int = 5

    @State private var vm = HomeViewModel()
    @State private var showPaywall: Bool = false
    @State private var showSettings: Bool = false
    @State private var showNotifications: Bool = false
    /// Active activity-row destination; presented as a full-screen cover so we
    /// don't depend on a NavigationStack (Home doesn't have one).
    @State private var activityDestination: ActivityDestination?

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
                        if vm.isLoading && vm.recentActivity.isEmpty {
                            loadingCard
                        } else if vm.recentActivity.isEmpty {
                            emptyCard("No activity yet. Create a group or add an expense to get started.")
                        } else {
                            // Landing page surfaces only the most recent
                            // activity items. Older entries live in the
                            // dedicated Activity tab.
                            ForEach(Array(vm.recentActivity.prefix(HomeView.recentActivityLimit))) { item in
                                Button {
                                    if let dest = destination(for: item) {
                                        activityDestination = dest
                                    }
                                } label: {
                                    ActivityRow(activity: item)
                                }
                                .buttonStyle(.plain)
                                .disabled(destination(for: item) == nil)
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        SectionHeader(title: "Your Groups")
                        if vm.isLoading && vm.groups.isEmpty {
                            loadingCard
                        } else if vm.groups.isEmpty {
                            emptyCard("You aren't in any groups yet.")
                        } else {
                            ForEach(vm.groups.prefix(1)) { group in
                                Button {
                                    activityDestination = .group(group)
                                } label: {
                                    HomeGroupRow(group: group)
                                }
                                .buttonStyle(.plain)
                            }
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
        .sheet(isPresented: $showNotifications) {
            NotificationsSheetView()
        }
        .fullScreenCover(item: $activityDestination, onDismiss: {
            Task { await vm.load() }
        }) { destination in
            NavigationStack {
                switch destination {
                case .group(let group):
                    GroupDetailView(group: group)
                case .friend(let friend):
                    FriendHistoryView(friend: friend)
                }
            }
        }
    }

    /// Resolve where an activity row should navigate. Group rows take priority
    /// (they're more specific); fall back to friend rows for 1-1 expenses,
    /// settlements, and friendship-accepted activity.
    private func destination(for item: ActivityItem) -> ActivityDestination? {
        if let groupId = item.groupId, let group = vm.groupsById[groupId] {
            return .group(group)
        }
        if let friendId = item.friendId, let friend = vm.friendsById[friendId] {
            return .friend(friend)
        }
        return nil
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
                Button { showNotifications = true } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                }
                // Premium / paywall entry — re-enable when subscription ships.
                // Button { showPaywall = true } label: {
                //     Image(systemName: "crown.fill")
                //         .font(.system(size: 18, weight: .semibold))
                //         .foregroundStyle(AppColor.goldAccent)
                // }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }

    private var loadingCard: some View {
        ProgressView()
            .tint(AppColor.pandaBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColor.cardHairline, lineWidth: 1)
            )
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
