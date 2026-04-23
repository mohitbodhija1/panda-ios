//
//  MainTabView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Post-auth shell that swaps between Home / Friends / Groups / Activity
//  and overlays the custom PandaTabBar.
//

import SwiftUI

struct MainTabView: View {
    @State private var selection: MainTab = .home
    @State private var showAddExpense: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .padding(.bottom, 74)

            PandaTabBar(selection: $selection, onFabTap: { showAddExpense = true })
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showAddExpense) {
            AddExpenseView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .home:
            HomeView()
        case .friends:
            NavigationStack { FriendsView() }
        case .groups:
            NavigationStack { GroupsListView() }
        case .activity:
            ActivityView()
        }
    }
}

#Preview {
    MainTabView()
}
