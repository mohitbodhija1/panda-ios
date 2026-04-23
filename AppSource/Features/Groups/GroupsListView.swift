//
//  GroupsListView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct GroupsListView: View {
    @State private var vm = GroupsListViewModel()

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header

                    if vm.groups.isEmpty && !vm.isLoading {
                        emptyCard
                    } else {
                        ForEach(vm.groups) { group in
                            NavigationLink(value: group) {
                                HomeGroupRow(group: group)
                            }
                            .buttonStyle(.plain)
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
                .padding(.top, 4)
            }
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
        .navigationDestination(for: GroupRowItem.self) { group in
            GroupDetailView(group: group)
        }
        .navigationDestination(for: GroupsRoute.self) { route in
            switch route {
            case .addGroup: AddGroupView()
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Text("Groups")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            NavigationLink(value: GroupsRoute.addGroup) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.pandaBlue))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private var emptyCard: some View {
        Text("You haven't created or been added to any groups yet.\nTap + to create your first group.")
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
