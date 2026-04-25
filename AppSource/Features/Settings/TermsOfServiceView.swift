//
//  TermsOfServiceView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  In-app Terms of Service / End User Licence Agreement. Required for App
//  Store / Play Store submission. Pair with `PrivacyPolicyView` and keep the
//  `lastUpdated` date in sync with material changes.
//

import SwiftUI

struct TermsOfServiceView: View {
    private static let supportEmail = "mbodhija80@gmail.com"

    var body: some View {
        LegalDocumentView(
            title: "Terms & Conditions",
            lastUpdated: "April 25, 2026",
            sections: Self.sections
        )
    }

    private static let sections: [LegalSection] = [
        LegalSection(
            title: "1. Acceptance of terms",
            body: """
            These Terms & Conditions ("Terms") govern your use of the PandaSplit \
            mobile application and related services (the "Service"). By creating an \
            account or using the Service, you agree to these Terms. If you do not \
            agree, do not use the Service.
            """
        ),
        LegalSection(
            title: "2. Eligibility",
            body: """
            You must be at least 13 years old to use PandaSplit. By using the Service, \
            you represent that you meet this requirement and that you have the legal \
            capacity to enter into these Terms.
            """
        ),
        LegalSection(
            title: "3. Your account",
            body: """
            You are responsible for safeguarding your account credentials and for any \
            activity that occurs under your account. Notify us immediately at \
            \(supportEmail) if you suspect unauthorised use.
            """
        ),
        LegalSection(
            title: "4. Acceptable use",
            body: """
            You agree not to:
            • Use the Service for any illegal, fraudulent, or harmful activity.
            • Upload content that is unlawful, defamatory, or infringes the rights of \
            others.
            • Attempt to access data that does not belong to you, reverse engineer the \
            Service, or interfere with its operation.
            """
        ),
        LegalSection(
            title: "5. Your content",
            body: """
            You retain ownership of the data you submit (groups, expenses, notes, \
            attachments). By submitting content, you grant us a limited licence to \
            store, process, and transmit it for the sole purpose of operating the \
            Service for you and the people you share with.
            """
        ),
        LegalSection(
            title: "6. Subscriptions and payments",
            body: """
            Some features may be offered as paid subscriptions. Pricing, billing \
            cycles, and renewal terms are presented at the point of purchase and are \
            processed by the App Store or Play Store under their standard terms. You \
            can manage or cancel subscriptions through your store account.
            """
        ),
        LegalSection(
            title: "7. Disclaimers",
            body: """
            The Service is provided "as is" and "as available" without warranties of \
            any kind, express or implied. PandaSplit is a tool for tracking shared \
            expenses; we do not provide financial, legal, or accounting advice and we \
            do not guarantee the accuracy of any calculation.
            """
        ),
        LegalSection(
            title: "8. Limitation of liability",
            body: """
            To the maximum extent permitted by law, PandaSplit and its operators will \
            not be liable for any indirect, incidental, consequential, or special \
            damages arising out of or in connection with your use of the Service.
            """
        ),
        LegalSection(
            title: "9. Termination",
            body: """
            You may stop using the Service at any time. We may suspend or terminate \
            your account if you violate these Terms or if doing so is required to \
            protect the Service or other users.
            """
        ),
        LegalSection(
            title: "10. Changes",
            body: """
            We may update these Terms from time to time. The updated Terms become \
            effective when posted in the app. Continued use of the Service after the \
            update constitutes acceptance of the revised Terms.
            """
        ),
        LegalSection(
            title: "11. Contact",
            body: """
            For questions about these Terms, contact us at \(supportEmail).
            """
        )
    ]
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
