//
//  AppFont.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Shared type ramp used across the onboarding and main surfaces.
//

import SwiftUI

enum AppFont {
    static let heroTitle   = Font.system(size: 30, weight: .bold, design: .rounded)
    static let pageTitle   = Font.system(size: 26, weight: .bold, design: .rounded)
    static let navTitle    = Font.system(size: 17, weight: .semibold)
    static let sectionTitle = Font.system(size: 15, weight: .semibold)
    static let bodyRegular = Font.system(size: 15, weight: .regular)
    static let bodyStrong  = Font.system(size: 15, weight: .semibold)
    static let rowTitle    = Font.system(size: 16, weight: .semibold)
    static let rowSubtitle = Font.system(size: 13, weight: .regular)
    static let button      = Font.system(size: 17, weight: .semibold)
    static let caption     = Font.system(size: 13, weight: .regular)
    static let amount      = Font.system(size: 18, weight: .bold, design: .rounded)
    static let amountSmall = Font.system(size: 14, weight: .semibold)
    static let priceBig    = Font.system(size: 28, weight: .bold, design: .rounded)
    static let avatarPrice = Font.system(size: 12, weight: .semibold)
}
