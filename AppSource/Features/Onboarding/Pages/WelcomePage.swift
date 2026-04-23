//
//  WelcomePage.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Onboarding page 1 – hero panda logo with "Get Started" CTA.
//

import SwiftUI

struct WelcomePage: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image("panda_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 168, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: AppColor.pandaBlue.opacity(0.18), radius: 22, x: 0, y: 12)
                .padding(.bottom, 28)

            titleLine
                .padding(.bottom, 12)

            Text("Easily track, split, and settle\nbills with friends and groups.")
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Spacer(minLength: 24)

            VStack(spacing: 18) {
                PrimaryButton(title: "Get Started") { viewModel.advance() }

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(AppColor.textSecondary)
                    Button("Log in") { viewModel.logIn() }
                        .foregroundStyle(AppColor.pandaBlue)
                        .fontWeight(.semibold)
                }
                .font(AppFont.caption)

                PageDots(count: viewModel.pageCount, selectedIndex: viewModel.currentIndex)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
    }

    private var titleLine: some View {
        Text("Split \(Text("expenses").foregroundStyle(AppColor.pandaBlue)). Stress less.")
            .font(AppFont.heroTitle)
            .foregroundStyle(AppColor.textPrimary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        OnboardingBackground()
        WelcomePage()
    }
    .environment(OnboardingViewModel())
}
