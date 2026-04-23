//
//  OnboardingFlowView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Paged container that swipes between the four onboarding pages.
//

import SwiftUI

struct OnboardingFlowView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ZStack {
            OnboardingBackground()

            TabView(selection: $bindableViewModel.currentIndex) {
                WelcomePage().tag(OnboardingPage.welcome.rawValue)
                FriendsPage().tag(OnboardingPage.friends.rawValue)
                GroupsPage().tag(OnboardingPage.groups.rawValue)
                DonePage().tag(OnboardingPage.done.rawValue)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentIndex)
        }
        .environment(viewModel)
    }
}

#Preview {
    OnboardingFlowView()
}
