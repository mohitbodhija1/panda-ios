//
//  LegalDocumentView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Reusable shell for legal copy (Privacy Policy, Terms of Service). Renders a
//  navigation bar with a back chevron, an effective-date subtitle, and a
//  scrolling stack of titled sections. Concrete documents only need to provide
//  the section list; the chrome stays consistent across the app.
//

import SwiftUI

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct LegalDocumentView: View {
    let title: String
    let lastUpdated: String
    let sections: [LegalSection]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    navBar

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(AppFont.pageTitle)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Last updated \(lastUpdated)")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    VStack(spacing: 12) {
                        ForEach(sections) { section in
                            sectionCard(section)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func sectionCard(_ section: LegalSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(section.body)
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppColor.cardHairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(
            title: "Privacy Policy",
            lastUpdated: "April 25, 2026",
            sections: [
                LegalSection(title: "1. Overview", body: "Lorem ipsum dolor sit amet."),
                LegalSection(title: "2. Data we collect", body: "Lorem ipsum dolor sit amet.")
            ]
        )
    }
}
