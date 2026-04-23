//
//  SupabaseEnvironment.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Reads SUPABASE_URL and SUPABASE_ANON_KEY from Info.plist (preferred)
//  or from environment variables (debug). Set them once in Build Settings or
//  in your scheme's Info.plist user-defined keys.
//

import Foundation

enum SupabaseEnvironment {
    /// Hosted Supabase project. Overridable via `SUPABASE_URL` in `Info.plist`
    /// or the process environment so CI / local-stack builds can point elsewhere.
    private static let defaultURL = "https://eykwlwrwqmfilgzrzghj.supabase.co"

    /// `anon` public key. This key is designed to be shipped to clients; all
    /// data access is gated by RLS policies on the server. Rotate it in the
    /// Supabase dashboard if needed.
    private static let defaultAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5a3dsd3J3cW1maWxnenJ6Z2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjcwNTIsImV4cCI6MjA5MjQ0MzA1Mn0.dPVE243UalIgH2sXGFnCMLSRUDFj5TabIMyPmrDmQlI"

    static let url: URL = {
        let raw = value(for: "SUPABASE_URL") ?? defaultURL
        return URL(string: raw) ?? URL(string: defaultURL)!
    }()

    static let anonKey: String = {
        value(for: "SUPABASE_ANON_KEY") ?? defaultAnonKey
    }()

    private static func value(for key: String) -> String? {
        if let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, !v.isEmpty {
            return v
        }
        if let v = ProcessInfo.processInfo.environment[key], !v.isEmpty {
            return v
        }
        return nil
    }
}
