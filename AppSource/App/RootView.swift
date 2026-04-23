//
//  RootView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Three-stage gate: Onboarding -> Auth -> Main App.
//  Authentication is now driven by a real Supabase session via AuthSession;
//  the legacy @AppStorage("isAuthenticated") flag is kept only as a compat
//  shim for any preview / mock paths.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var session = AuthSession()

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingFlowView()
            } else if session.isLoading {
                loadingScreen
            } else if !session.isAuthenticated {
                AuthFlowView()
            } else {
                MainTabView()
            }
        }
        .environment(session)
        .animation(.easeInOut, value: hasCompletedOnboarding)
        .animation(.easeInOut, value: session.isAuthenticated)
    }

    private var loadingScreen: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()
            ProgressView().tint(AppColor.pandaBlue)
        }
    }
}

#Preview {
    RootView()
}
