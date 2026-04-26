//
//  SectionHeader.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var action: String = "View all"
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            // Only render the trailing action button when a callback is wired.
            // Home doesn't currently have working "View all" destinations and
            // a no-op button is worse than no button at all.
            if let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.pandaBlue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    SectionHeader(title: "Recent Activity")
        .padding()
}
