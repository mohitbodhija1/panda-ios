//
//  OnboardingBackground.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Shared soft-blue → white vertical gradient used behind every onboarding page.
//

import SwiftUI

struct OnboardingBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppColor.bgTop, .white],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingBackground()
}
