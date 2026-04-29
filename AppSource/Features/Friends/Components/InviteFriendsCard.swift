//
//  InviteFriendsCard.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct InviteFriendsCard: View {
    private static let appStoreURL = URL(string: "https://apps.apple.com/in/app/pandasplit-split-bills/id6763338956")!

    private static var shareMessage: String {
        let name = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "PandaSplit"
        return "Let's split expenses on \(name). Download the app and we can track shared costs together."
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColor.chipBlue)
                    .frame(width: 44, height: 44)
                Image(systemName: "link")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Invite friends")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Share your link and split faster")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            ShareLink(item: Self.appStoreURL,
                      subject: Text("Join me on PandaSplit"),
                      message: Text("\(Self.shareMessage)\n\(Self.appStoreURL.absoluteString)")) {
                Text("Share")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppColor.chipBlue))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColor.cardHairline, lineWidth: 1)
        )
    }
}

#Preview {
    InviteFriendsCard().padding().background(AppColor.bgTop)
}
