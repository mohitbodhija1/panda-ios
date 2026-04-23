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
            Button {
                onAction?()
            } label: {
                Text(action)
                    .font(AppFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.pandaBlue)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    SectionHeader(title: "Recent Activity")
        .padding()
}
