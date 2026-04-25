//
//  TintedFormRow.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Reusable form row used by Add Group / Add Expense: leading tinted icon
//  chip, two-line label/value stack, optional trailing accessory and chevron.
//

import SwiftUI

struct TintedFormRow: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String
    var isPlaceholder: Bool = false
    var trailingChevron: Bool = false
    var trailingAccessory: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.45))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)

                HStack(spacing: 6) {
                    Text(value)
                        .font(AppFont.bodyRegular)
                        .foregroundStyle(isPlaceholder ? AppColor.textSecondary : AppColor.textPrimary)
                    if let accessory = trailingAccessory {
                        Text(accessory)
                            .font(.system(size: 14))
                    }
                }
            }

            Spacer(minLength: 8)

            if trailingChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

/// Editable variant of `TintedFormRow` that swaps the display-only value for a
/// real `TextField`. Keeps the same chrome so forms look identical to the mocks.
struct TintedFormRowField: View {
    let icon: String
    let tint: Color
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.45))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.pandaBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)

                Group {
                    if isSecure {
                        SecureField(
                            "",
                            text: $text,
                            prompt: Text(placeholder).foregroundStyle(AppColor.textSecondary)
                        )
                    } else {
                        TextField(
                            "",
                            text: $text,
                            prompt: Text(placeholder).foregroundStyle(AppColor.textSecondary)
                        )
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocap)
                        .autocorrectionDisabled(keyboard == .emailAddress || keyboard == .URL)
                    }
                }
                .font(AppFont.bodyRegular)
                .foregroundStyle(AppColor.textPrimary)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

/// Vertical stack of `TintedFormRow`s rendered as one rounded white card with hairline dividers.
struct TintedFormCard<Content: View>: View {
    @ViewBuilder var rows: Content

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(_FormCardLayout()) {
                rows
            }
        }
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

private struct _FormCardLayout: _VariadicView_UnaryViewRoot {
    func body(children: _VariadicView.Children) -> some View {
        let last = children.last?.id
        VStack(spacing: 0) {
            ForEach(children) { child in
                child
                if child.id != last {
                    Divider()
                        .overlay(AppColor.cardHairline)
                        .padding(.leading, 66)
                }
            }
        }
    }
}

#Preview {
    TintedFormCard {
        TintedFormRow(
            icon: "person.crop.circle",
            tint: AppColor.chipBlue,
            title: "Group Name",
            value: "e.g. Goa Trip, Flatmates",
            isPlaceholder: true
        )
        TintedFormRow(
            icon: "note.text",
            tint: AppColor.avatarTintE,
            title: "Description (Optional)",
            value: "Add a description",
            isPlaceholder: true
        )
        TintedFormRow(
            icon: "person.2.fill",
            tint: AppColor.chipBlue,
            title: "Add Members",
            value: "Select friends to add",
            isPlaceholder: true,
            trailingChevron: true
        )
    }
    .padding()
    .background(AppColor.bgTop)
}
