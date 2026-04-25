//
//  SearchBar.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Non-interactive pill search affordance used on the Friends tab.
//

import SwiftUI

struct SearchBar: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(AppColor.textSecondary)
            )
                .font(AppFont.bodyRegular)
                .foregroundStyle(Color.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(
            Capsule().fill(AppColor.authFieldBg)
        )
    }
}

#Preview {
    SearchBar(placeholder: "Search friends", text: .constant(""))
        .padding()
}
