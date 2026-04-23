//
//  AddFriendView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

struct AddFriendView: View {
    @State private var vm = AddFriendViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.bgTop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    navBar

                    Text("Invite a friend to start splitting\nexpenses together.")
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Image("pandas_highfive")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 190)

                    AvatarPickerCircle()
                        .padding(.top, -16)

                    TintedFormCard {
                        TintedFormRowField(
                            icon: "person.fill",
                            tint: AppColor.chipBlue,
                            title: "Friend Name",
                            placeholder: "e.g. Ava Williams",
                            text: Binding(get: { vm.name }, set: { vm.name = $0 }),
                            autocap: .words
                        )
                        TintedFormRowField(
                            icon: "envelope.fill",
                            tint: AppColor.avatarTintE,
                            title: "Email Address",
                            placeholder: "Enter friend's email",
                            text: Binding(get: { vm.email }, set: { vm.email = $0 }),
                            keyboard: .emailAddress,
                            autocap: .never
                        )
                        TintedFormRowField(
                            icon: "phone.fill",
                            tint: AppColor.avatarTintD,
                            title: "Phone Number (Optional)",
                            placeholder: "Add phone number",
                            text: Binding(get: { vm.phone }, set: { vm.phone = $0 }),
                            keyboard: .phonePad,
                            autocap: .never
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

            PrimaryButton(title: vm.isSubmitting ? "Sending…" : "Send Invite") {
                Task {
                    if await vm.submit() { dismiss() }
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

            Text("Add Friend")
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
    }
}
