//
//  FriendsView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct FriendsView: View {
    @State private var vm = FriendsViewModel()

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar

                    SearchBar(placeholder: "Search friends", text: Binding(
                        get: { vm.searchText },
                        set: { vm.searchText = $0 }
                    ))

                    FriendsPromoCard()

                    if !vm.incomingRequests.isEmpty {
                        requestsSection
                    }

                    friendsSection

                    if vm.hasAnyOutgoing {
                        invitedSection
                    }

                    InviteFriendsCard()

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
        .navigationDestination(for: FriendsRoute.self) { route in
            switch route {
            case .addFriend:
                AddFriendView()
            case .addExpense(let friend):
                AddExpenseView(preselectedFriend: friend)
            }
        }
    }

    // MARK: - Sections

    private var friendsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Your Friends")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(vm.friends.count) total")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            if vm.friends.isEmpty {
                emptyCard("You haven't added any friends yet. Invite someone to get started.")
            } else {
                ForEach(vm.filtered) { friend in
                    NavigationLink(value: FriendsRoute.addExpense(friend)) {
                        FriendRow(friend: friend)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var requestsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Friend Requests")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(vm.incomingRequests.count) new")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            ForEach(vm.filteredIncoming) { friend in
                FriendRequestRow(
                    friend: friend,
                    isBusy: vm.pendingActionIds.contains(friend.id),
                    onAccept: { Task { await vm.acceptRequest(friend) } },
                    onDecline: { Task { await vm.declineRequest(friend) } }
                )
            }
        }
    }

    private var invitedSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Invited")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(vm.outgoingInvites.count + vm.pendingInvites.count) pending")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            ForEach(vm.filteredOutgoing) { friend in
                NavigationLink(value: FriendsRoute.addExpense(friend)) {
                    FriendRow(friend: friend)
                }
                .buttonStyle(.plain)
            }

            ForEach(vm.filteredPendingInvites) { invite in
                PendingInviteRow(invite: invite)
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Text("Friends")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            NavigationLink(value: FriendsRoute.addFriend) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.chipBlue))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
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
