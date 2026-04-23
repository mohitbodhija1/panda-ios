//
//  AddGroupView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct AddGroupView: View {
    @State private var vm = AddGroupViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    navBar

                    VStack(spacing: 4) {
                        Text("Create a group for trips, flatmates,\nevents, and more.")
                            .font(AppFont.bodyRegular)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    Image("pandas_group")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 190)

                    AvatarPickerCircle()
                        .padding(.top, -16)

                    TintedFormCard {
                        TintedFormRowField(
                            icon: "person.crop.circle",
                            tint: AppColor.chipBlue,
                            title: "Group Name",
                            placeholder: "e.g. Goa Trip, Flatmates",
                            text: Binding(get: { vm.name }, set: { vm.name = $0 })
                        )
                        TintedFormRowField(
                            icon: "note.text",
                            tint: AppColor.avatarTintE,
                            title: "Description (Optional)",
                            placeholder: "Add a description",
                            text: Binding(get: { vm.description }, set: { vm.description = $0 })
                        )
                        CurrencyPickerRow(
                            icon: "dollarsign.circle",
                            tint: AppColor.avatarPink,
                            title: "Default Currency",
                            code: Binding(get: { vm.defaultCurrency }, set: { vm.defaultCurrency = $0 })
                        )
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }

            PrimaryButton(title: vm.isSubmitting ? "Creating…" : "Create Group") {
                Task {
                    if await vm.submit() {
                        dismiss()
                    }
                }
            }
            .disabled(!vm.canSubmit)
            .opacity(vm.canSubmit ? 1 : 0.6)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [AppColor.bgTop.opacity(0), AppColor.bgTop],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 90)
                .offset(y: 20),
                alignment: .top
            )
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppColor.cardHairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Create Group")
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }
}
