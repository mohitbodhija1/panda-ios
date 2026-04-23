//
//  GroupsPage.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Onboarding page 3 – splitting costs inside groups.
//

import SwiftUI

struct GroupsPage: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OnboardingBackButton { viewModel.back() }
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 4)

            titleLine
                .padding(.top, 4)

            Text("Create groups for trips, flatmates,\nevents, and more.")
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)

            Image("pandas_group")
                .resizable()
                .scaledToFit()
                .frame(height: 210)
                .padding(.top, 4)

            VStack(spacing: 12) {
                OptionRow(
                    icon: "person.3.fill",
                    title: "Create Group",
                    subtitle: "Start a new group",
                    trailing: .plus
                )
                OptionRow(
                    icon: "person.badge.plus",
                    title: "Join Group",
                    subtitle: "Join with invite code"
                )
                OptionRow(
                    icon: "square.grid.2x2",
                    title: "Explore Groups",
                    subtitle: "See your existing groups"
                )
            }
            .padding(.top, 4)

            Spacer(minLength: 20)

            VStack(spacing: 14) {
                PrimaryButton(title: "Continue") { viewModel.advance() }

                Button("Skip for now") { viewModel.skip() }
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.textSecondary)

                PageDots(count: viewModel.pageCount, selectedIndex: viewModel.currentIndex)
                    .padding(.top, 2)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
    }

    private var titleLine: some View {
        Text("Split in \(Text("groups").foregroundStyle(AppColor.pandaBlue))")
            .font(AppFont.pageTitle)
            .foregroundStyle(AppColor.textPrimary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        OnboardingBackground()
        GroupsPage()
    }
    .environment(OnboardingViewModel())
}
