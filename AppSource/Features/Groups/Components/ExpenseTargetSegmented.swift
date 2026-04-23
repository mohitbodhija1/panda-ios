//
//  ExpenseTargetSegmented.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Splitwise-style toggle that switches the Add Expense flow between picking
//  a group or a single friend. Visual language mirrors ExpensesSegmented so
//  the two pill controls feel like the same family.
//

import SwiftUI

enum ExpenseTarget: String, CaseIterable, Hashable {
    case group   = "Group"
    case friends = "Friends"

    var icon: String {
        switch self {
        case .group:   return "person.2.fill"
        case .friends: return "person.crop.circle.fill"
        }
    }
}

struct ExpenseTargetSegmented: View {
    @Binding var selection: ExpenseTarget

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ExpenseTarget.allCases, id: \.self) { target in
                pill(target)
            }
        }
        .padding(4)
        .background(Capsule().fill(AppColor.chipBlue))
    }

    private func pill(_ target: ExpenseTarget) -> some View {
        let isActive = selection == target
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selection = target }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: target.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(target.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isActive ? AppColor.pandaBlue : AppColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isActive {
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: AppColor.textPrimary.opacity(0.08), radius: 6, x: 0, y: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExpenseTargetSegmented(selection: .constant(.group))
        .padding()
        .background(AppColor.bgTop)
}
