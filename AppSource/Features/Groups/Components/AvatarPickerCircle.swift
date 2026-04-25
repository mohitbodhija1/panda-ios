//
//  AvatarPickerCircle.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Circular avatar affordance with a camera badge. Used on Add Group and as
//  the label for `PhotosPicker` on Add Friend. When `avatarData` is non-nil,
//  shows a downscaled preview image instead of the default glyph.
//

import SwiftUI
import UIKit

struct AvatarPickerCircle: View {
    /// Raw image bytes from `PhotosPicker` / `Data`; optional preview only.
    var avatarData: Data? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatarData,
                   let ui = UIImage(data: avatarData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColor.pandaBlue.opacity(0.85))
                }
            }
            .frame(width: 64, height: 64)
            .background(Circle().fill(AppColor.avatarTintE.opacity(0.55)))
            .clipShape(Circle())

            Image(systemName: "camera.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(AppColor.pandaBlue))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 2, y: 2)
        }
    }
}

#Preview {
    AvatarPickerCircle()
        .padding()
        .background(AppColor.bgTop)
}
