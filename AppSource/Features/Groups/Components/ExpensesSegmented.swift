//
//  ExpensesSegmented.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI

enum GroupSegment: String, CaseIterable, Hashable {
    case expenses = "Expenses"
    case members  = "Members"
}

struct ExpensesSegmented: View {
    @Binding var selection: GroupSegment

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GroupSegment.allCases, id: \.self) { segment in
                pill(segment)
            }
        }
        .padding(4)
        .background(
            Capsule().fill(AppColor.chipBlue)
        )
    }

    private func pill(_ segment: GroupSegment) -> some View {
        let isActive = selection == segment
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selection = segment }
        } label: {
            Text(segment.rawValue)
                .font(.system(size: 14, weight: .semibold))
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
    ExpensesSegmented(selection: .constant(.expenses))
        .padding()
        .background(AppColor.bgTop)
}
