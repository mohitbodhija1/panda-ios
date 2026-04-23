//
//  DonePage.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Onboarding page 4 – hero expense preview plus the closing CTA.
//

import SwiftUI

struct DonePage: View {
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

            Text("Add expenses, split fairly,\nand settle up easily.")
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)

            ExpensePreviewCard()
                .padding(.top, 18)

            VStack(spacing: 12) {
                OptionRow(
                    icon: "plus.square.fill",
                    title: "Add Expense",
                    subtitle: "Track any expense",
                    trailing: .plus
                )
                OptionRow(
                    icon: "checkmark.seal.fill",
                    title: "Settle Up",
                    subtitle: "See who owes what"
                )
                OptionRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    title: "Get Paid Back",
                    subtitle: "Easy settlements"
                )
            }
            .padding(.top, 14)

            Spacer(minLength: 18)

            VStack(spacing: 14) {
                PrimaryButton(title: "Let's Go!") { viewModel.advance() }

                PageDots(count: viewModel.pageCount, selectedIndex: viewModel.currentIndex)
                    .padding(.top, 2)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
    }

    private var titleLine: some View {
        Text("Split. Settle. \(Text("Done.").foregroundStyle(AppColor.pandaBlue))")
            .font(AppFont.pageTitle)
            .foregroundStyle(AppColor.textPrimary)
            .multilineTextAlignment(.center)
    }
}

private struct ExpensePreviewCard: View {
    private let avatars: [Color] = [
        AppColor.avatarPink,
        AppColor.avatarBlue,
        AppColor.avatarGreen,
        AppColor.avatarOrange
    ]

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Text("Dinner at Joe's")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("🍕")
                        .font(.system(size: 16))
                }
                Spacer()
                Text("$120.00")
                    .font(AppFont.amount)
                    .foregroundStyle(AppColor.textPrimary)
            }

            Text("Split between 4 people")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)

            HStack(spacing: 14) {
                ForEach(0..<avatars.count, id: \.self) { i in
                    VStack(spacing: 6) {
                        avatarView(tint: avatars[i])
                        Text("$30.00")
                            .font(AppFont.avatarPrice)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func avatarView(tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(tint)
            Image("panda_logo")
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 46)
                .clipShape(Circle())
        }
        .frame(width: 46, height: 46)
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }
}

#Preview {
    ZStack {
        OnboardingBackground()
        DonePage()
    }
    .environment(OnboardingViewModel())
}
