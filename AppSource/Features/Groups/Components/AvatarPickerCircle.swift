//
//  AvatarPickerCircle.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Lavender circle with two-people glyph and a small camera badge,
//  used as the (illustrative) avatar picker on Add Group.
//

import SwiftUI

struct AvatarPickerCircle: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppColor.avatarTintE.opacity(0.55))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue.opacity(0.85))
                    .frame(width: 64, height: 64)

                Image(systemName: "camera.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(AppColor.pandaBlue))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AvatarPickerCircle()
        .padding()
        .background(AppColor.bgTop)
}
