//
//  AddGroupView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct AddGroupView: View {
    @State private var vm = AddGroupViewModel()
    @State private var showFriendsPicker: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
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

                    VStack(spacing: 10) {
                        Image(GroupAvatar.imageName(for: vm.selectedAvatarKey, groupId: nil))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 124, height: 124)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColor.cardHairline, lineWidth: 1)
                            )
                        Text("Pick your group avatar")
                            .font(AppFont.rowSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                        HStack(spacing: 12) {
                            ForEach(GroupAvatar.keys, id: \.self) { key in
                                Button {
                                    vm.selectedAvatarKey = key
                                } label: {
                                    Image(key)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 46, height: 46)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(vm.selectedAvatarKey == key ? AppColor.pandaBlue : AppColor.cardHairline,
                                                        lineWidth: vm.selectedAvatarKey == key ? 2 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

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
                        Button { showFriendsPicker = true } label: {
                            TintedFormRow(
                                icon: "person.2.fill",
                                tint: AppColor.chipBlue,
                                title: "Add Friends",
                                value: vm.selectedFriendsLabel,
                                isPlaceholder: vm.selectedMemberIds.isEmpty,
                                trailingChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let message = vm.errorMessage {
                        Text(message)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.negative)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .scrollDismissesKeyboardForForms()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
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
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [AppColor.bgTop.opacity(0), AppColor.bgTop],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        .offset(y: -24),
                        alignment: .top
                    )
                    .background(AppColor.bgTop)
                }
            }
        }
        .keyboardDismissToolbar()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await vm.loadFriends() }
        .sheet(isPresented: $showFriendsPicker) {
            FriendsMultiPickerSheet(
                title: "Add Friends",
                confirmTitle: "Done",
                initialSelection: vm.selectedMemberIds
            ) { picked in
                vm.selectedMemberIds = picked
            }
            .presentationDetents([.large])
        }
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
