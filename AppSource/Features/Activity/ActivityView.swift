//
//  ActivityView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct ActivityView: View {
    @State private var vm = ActivityViewModel()

    var body: some View {
        ZStack {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Activity")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Button { /* illustrative filter */ } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColor.pandaBlue)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(AppColor.chipBlue))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)

                    if vm.feed.isEmpty && !vm.isLoading {
                        empty
                    } else {
                        ForEach(vm.feed) { ActivityRow(activity: $0) }
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
            }
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
    }

    private var empty: some View {
        Text("Nothing's happened yet. Once expenses, settlements, or group changes occur they'll show up here.")
            .font(AppFont.bodyRegular)
            .foregroundStyle(AppColor.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColor.cardHairline, lineWidth: 1)
            )
    }
}
