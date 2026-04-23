//
//  PaywallView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Modal paywall surface. Tapping any CTA dismisses the sheet — no real
//  purchase happens (illustrative only until StoreKit wiring lands).
//

import SwiftUI

struct PaywallView: View {
    enum Plan: Hashable { case monthly, yearly }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 16)
                    heroBadge

                    VStack(spacing: 6) {
                        Text("Upgrade to")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.textSecondary)
                        titleAttributed
                            .font(AppFont.heroTitle)
                            .multilineTextAlignment(.center)
                        Text("Unlock unlimited splitting and smarter\ninsights for your crew.")
                            .font(AppFont.bodyRegular)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    featuresCard

                    HStack(spacing: 12) {
                        PricingCard(
                            title: "Monthly",
                            price: "$4.99",
                            caption: "per month",
                            isSelected: selectedPlan == .monthly,
                            isBestValue: false,
                            action: { selectedPlan = .monthly }
                        )
                        PricingCard(
                            title: "Yearly",
                            price: "$39.99",
                            caption: "per year · save 33%",
                            isSelected: selectedPlan == .yearly,
                            isBestValue: true,
                            action: { selectedPlan = .yearly }
                        )
                    }

                    PrimaryButton(title: "Continue") { dismiss() }

                    Button("Not now, maybe later") { dismiss() }
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppColor.cardHairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.leading, 20)
        }
    }

    private var titleAttributed: Text {
        Text("Panda \(Text("Premium").foregroundStyle(AppColor.pandaBlue))")
    }

    private var heroBadge: some View {
        ZStack {
            Circle()
                .fill(AppColor.chipBlue)
                .frame(width: 140, height: 140)

            Image("panda_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            Image(systemName: "crown.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppColor.goldAccent)
                .shadow(color: AppColor.goldAccent.opacity(0.35), radius: 6, x: 0, y: 2)
                .offset(y: -62)
        }
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaywallFeatureRow(icon: "infinity.circle.fill",  title: "Unlimited Groups",    subtitle: "Create as many groups as you need")
            PaywallFeatureRow(icon: "chart.bar.fill",         title: "Advanced Analytics",  subtitle: "See trends across months and categories")
            PaywallFeatureRow(icon: "square.and.arrow.up.fill", title: "Export & Reports", subtitle: "Share CSV and PDF statements")
            PaywallFeatureRow(icon: "lifepreserver.fill",     title: "Priority Support",    subtitle: "Skip the queue — we've got you")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }
}

#Preview {
    PaywallView()
}
