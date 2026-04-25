//
//  View+dismissKeyboard.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func resignFirstResponder() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    /// Pull-to-scroll dismisses the keyboard (iOS 16+).
    func scrollDismissesKeyboardForForms() -> some View {
        scrollDismissesKeyboard(.interactively)
    }

    /// Adds a **Done** button above the software keyboard (for decimal-pad
    /// fields that have no return key).
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { KeyboardDismiss.resignFirstResponder() }
            }
        }
    }
}
