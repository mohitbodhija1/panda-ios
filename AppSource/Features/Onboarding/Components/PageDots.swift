//
//  PageDots.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Custom 4-dot page indicator matching the onboarding mockups.
//

import SwiftUI

struct PageDots: View {
    let count: Int
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                let isActive = index == selectedIndex
                Capsule()
                    .fill(isActive ? AppColor.pandaBlue : AppColor.dotInactive)
                    .frame(width: isActive ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PageDots(count: 4, selectedIndex: 0)
        PageDots(count: 4, selectedIndex: 1)
        PageDots(count: 4, selectedIndex: 2)
        PageDots(count: 4, selectedIndex: 3)
    }
    .padding()
}
