//
//  FriendsPage.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Onboarding page 2 – introduces one-on-one splitting with friends.
//

import SwiftUI

struct FriendsPage: View {
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

            Text("Add your friends and split\nexpenses one-on-one.")
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)

            Image("pandas_highfive")
                .resizable()
                .scaledToFit()
                .frame(height: 210)
                .padding(.top, 4)

            VStack(spacing: 12) {
                OptionRow(
                    icon: "person.crop.circle.badge.plus",
                    title: "Add Friends",
                    subtitle: "Connect your contacts"
                )
                OptionRow(
                    icon: "qrcode.viewfinder",
                    title: "Scan & Add",
                    subtitle: "Scan QR to connect"
                )
                OptionRow(
                    icon: "link",
                    title: "Share Your Link",
                    subtitle: "Invite friends to join"
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
        Text("Split with \(Text("friends").foregroundStyle(AppColor.pandaBlue))")
            .font(AppFont.pageTitle)
            .foregroundStyle(AppColor.textPrimary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        OnboardingBackground()
        FriendsPage()
    }
    .environment(OnboardingViewModel())
}
