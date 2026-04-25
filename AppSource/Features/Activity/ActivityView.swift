//
//  ActivityView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct ActivityView: View {
    @State private var vm = ActivityViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgTop.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Activity")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                        }
                        .padding(.top, 4)

                        if vm.feed.isEmpty {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(AppColor.pandaBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                            } else {
                                empty
                            }
                        } else {
                            ForEach(vm.feed) { item in
                                if let destination = destination(for: item) {
                                    NavigationLink(value: destination) {
                                        ActivityRow(activity: item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    ActivityRow(activity: item)
                                }
                            }
                        }

                        if let message = vm.errorMessage {
                            Text(message)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.negative)
                                .multilineTextAlignment(.center)
                        }

                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 20)
                }
                .refreshable { await vm.load() }
            }
            .task { await vm.load() }
            .navigationDestination(for: ActivityDestination.self) { dest in
                switch dest {
                case .group(let g):  GroupDetailView(group: g)
                case .friend(let f): FriendHistoryView(friend: f)
                }
            }
        }
    }

    private func destination(for item: ActivityItem) -> ActivityDestination? {
        if let groupId = item.groupId, let group = vm.groupsById[groupId] {
            return .group(group)
        }
        if let friendId = item.friendId, let friend = vm.friendsById[friendId] {
            return .friend(friend)
        }
        return nil
    }

    private var empty: some View {
        Text("Nothing's happened yet. Once expenses, settlements, or group changes occur they'll show up here.")
            .font(AppFont.bodyRegular)
            .foregroundStyle(AppColor.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
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
