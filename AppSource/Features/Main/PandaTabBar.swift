//
//  PandaTabBar.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Custom 5-slot tab bar with a floating blue plus FAB in the center.
//

import SwiftUI

struct PandaTabBar: View {
    @Binding var selection: MainTab
    var onFabTap: () -> Void = {}

    private let orderedTabs: [MainTab?] = [
        .home, .friends, nil, .groups, .activity
    ]

    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(orderedTabs.enumerated()), id: \.offset) { _, tab in
                    if let tab {
                        tabItem(tab)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(
                Color.white
                    .ignoresSafeArea(edges: .bottom)
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColor.cardHairline)
                    .frame(height: 1)
            }

            fabButton
                .offset(y: -22)
        }
    }

    private func tabItem(_ tab: MainTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(selection == tab ? AppColor.pandaBlue : AppColor.textSecondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var fabButton: some View {
        Button(action: onFabTap) {
            ZStack {
                Circle()
                    .fill(AppColor.pandaBlue)
                    .frame(width: 58, height: 58)
                    .shadow(color: AppColor.pandaBlue.opacity(0.35), radius: 10, x: 0, y: 6)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        PandaTabBar(selection: .constant(.home))
    }
    .background(AppColor.bgTop)
}
