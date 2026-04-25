//
//  NotificationsSheetView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct NotificationsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var items: [NotificationDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgTop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.negative)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }

                        if isLoading && items.isEmpty {
                            ProgressView()
                                .tint(AppColor.pandaBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if items.isEmpty {
                            Text("No notifications yet.\nPull down to refresh when you have updates.")
                                .font(AppFont.bodyRegular)
                                .foregroundStyle(AppColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(items) { n in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(n.title)
                                            .font(AppFont.rowTitle)
                                            .foregroundStyle(AppColor.textPrimary)
                                        Text(n.body)
                                            .font(AppFont.caption)
                                            .foregroundStyle(AppColor.textSecondary)
                                        Text(n.createdAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(AppColor.textSecondary.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(AppColor.cardHairline, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboardForForms()
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await NotificationsService.shared.inbox(limit: 50)
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }
}
