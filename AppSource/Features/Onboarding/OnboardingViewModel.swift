//
//  OnboardingViewModel.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Drives the paged onboarding flow and persists the completion flag
//  used by RootView to gate the post-onboarding experience.
//

import SwiftUI
import Observation

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case friends
    case groups
    case done

    var id: Int { rawValue }
}

@MainActor
@Observable
final class OnboardingViewModel {
    var currentIndex: Int = 0

    var pageCount: Int { OnboardingPage.allCases.count }

    func advance() {
        if currentIndex < pageCount - 1 {
            withAnimation(.easeInOut) { currentIndex += 1 }
        } else {
            hand(off: .signUp)
        }
    }

    func back() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut) { currentIndex -= 1 }
    }

    /// "Skip for now" links on pages 2 & 3 — treat as sign-up funnel by default.
    func skip() {
        hand(off: .signUp)
    }

    /// "Log in" link on the welcome page.
    func logIn() {
        hand(off: .login)
    }

    private func hand(off destination: AuthStartDestination) {
        AuthStartDestination.set(destination)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
