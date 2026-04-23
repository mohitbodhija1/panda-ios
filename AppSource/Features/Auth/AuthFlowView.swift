//
//  AuthFlowView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Hosts login/sign-up inside a NavigationStack that starts on the
//  destination captured from the onboarding CTA the user tapped.
//

import SwiftUI

enum AuthRoute: Hashable {
    case signUp
}

struct AuthFlowView: View {
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .signUp: SignUpView()
                    }
                }
        }
        .onAppear {
            if AuthStartDestination.current == .signUp, path.isEmpty {
                path.append(.signUp)
            }
        }
    }
}

#Preview {
    AuthFlowView()
}
