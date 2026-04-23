//
//  GroupHero.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct GroupHero: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.chipBlue, AppColor.bgTop],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Image("pandas_group")
                .resizable()
                .scaledToFit()
                .padding(.vertical, 14)
        }
        .frame(height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }
}

#Preview {
    GroupHero().padding().background(AppColor.bgTop)
}
