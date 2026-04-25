//
//  PrivacyPolicyView.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  In-app privacy policy. Required for App Store / Play Store submission. The
//  text below is intentionally generic but accurate for the current data flows
//  (Supabase Auth, Postgres, push tokens). Keep `lastUpdated` in sync whenever
//  the data-handling story changes.
//

import SwiftUI

struct PrivacyPolicyView: View {
    private static let supportEmail = "mbodhija80@gmail.com"

    var body: some View {
        LegalDocumentView(
            title: "Privacy Policy",
            lastUpdated: "April 25, 2026",
            sections: Self.sections
        )
    }

    private static let sections: [LegalSection] = [
        LegalSection(
            title: "1. Overview",
            body: """
            PandaSplit ("we", "our", or "the app") helps you track shared expenses with \
            friends and groups. This Privacy Policy explains what information we collect, \
            why we collect it, and how we keep it safe. By creating an account, you agree \
            to the practices described below.
            """
        ),
        LegalSection(
            title: "2. Information we collect",
            body: """
            • Account information: your full name, email address, and password hash, \
            stored via Supabase Authentication.
            • Profile information: optional display name, avatar, default currency, and \
            phone number, if you choose to add them.
            • Expense and group data: groups you create or join, expenses, splits, \
            settlements, and any notes or attachments you add.
            • Device information: APNs push token, app version, and basic OS metadata, \
            used solely to deliver notifications.
            """
        ),
        LegalSection(
            title: "3. How we use your information",
            body: """
            We use your information to operate the app, sync your data across devices, \
            send relevant push notifications (for example, when a group member adds an \
            expense), and provide customer support. We do not sell your personal data, \
            and we do not use it for advertising.
            """
        ),
        LegalSection(
            title: "4. Sharing with other users",
            body: """
            Your name, avatar, and profile email become visible to people you accept as \
            friends or share a group with. Expenses you create are visible to the other \
            members of the same group. We do not expose your data to anyone outside the \
            groups and friendships you participate in.
            """
        ),
        LegalSection(
            title: "5. Service providers",
            body: """
            We rely on the following sub-processors to operate PandaSplit:
            • Supabase (database, authentication, storage, edge functions).
            • Apple Push Notification service (APNs) for push delivery.
            • Optional email/SMS providers when you invite a friend by email or phone.
            These providers process your data only on our behalf and under their own \
            published privacy and security commitments.
            """
        ),
        LegalSection(
            title: "6. Data retention and deletion",
            body: """
            We keep your account data for as long as your account is active. You can \
            delete your account at any time from Settings; deletion removes your \
            profile, expenses, splits, and settlements. To request manual deletion or \
            a copy of your data, email us at \(supportEmail).
            """
        ),
        LegalSection(
            title: "7. Security",
            body: """
            All traffic between the app and our servers is encrypted in transit using \
            HTTPS. Database access is gated by row-level security so that you can only \
            read and write data that belongs to you or to groups you are a member of.
            """
        ),
        LegalSection(
            title: "8. Children",
            body: """
            PandaSplit is not intended for children under 13. If you believe a child has \
            created an account, please contact us and we will remove the account.
            """
        ),
        LegalSection(
            title: "9. Changes to this policy",
            body: """
            We may update this Privacy Policy from time to time. When we do, we will \
            update the "Last updated" date at the top of this page and, where required, \
            notify you in the app.
            """
        ),
        LegalSection(
            title: "10. Contact us",
            body: """
            Questions, requests, or concerns about this policy? Email us at \
            \(supportEmail) and we will respond as soon as we can.
            """
        )
    ]
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
