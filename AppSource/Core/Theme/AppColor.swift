//
//  AppColor.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Centralised brand colour tokens sourced from the Assets catalogue.
//

import SwiftUI

enum AppColor {
    static let pandaBlue      = Color("PandaBlue")
    static let textPrimary    = Color("TextPrimary")
    static let textSecondary  = Color("TextSecondary")
    static let cardHairline   = Color("CardHairline")
    static let iconTintBg     = Color("IconTintBg")
    static let dotInactive    = Color("DotInactive")
    static let bgTop          = Color("BgTop")

    static let avatarPink     = Color("AvatarPink")
    static let avatarBlue     = Color("AvatarBlue")
    static let avatarGreen    = Color("AvatarGreen")
    static let avatarOrange   = Color("AvatarOrange")

    static let positive       = Color("Positive")
    static let negative       = Color("Negative")
    static let authFieldBg    = Color("AuthFieldBg")
    static let chipBlue       = Color("ChipBlue")
    static let goldAccent     = Color("GoldAccent")
    static let balanceNavy    = Color("BalanceNavy")
    static let balanceBlue    = Color("BalanceBlue")

    static let avatarTintA    = Color("AvatarTintA")
    static let avatarTintB    = Color("AvatarTintB")
    static let avatarTintC    = Color("AvatarTintC")
    static let avatarTintD    = Color("AvatarTintD")
    static let avatarTintE    = Color("AvatarTintE")

    /// Deterministic avatar tint derived from an entity id so the same user /
    /// group / expense always renders with the same pastel swatch even when
    /// servers don't store a colour column.
    static func tint(for id: UUID) -> Color {
        let palette: [Color] = [avatarTintA, avatarTintB, avatarTintC, avatarTintD, avatarTintE]
        let firstByte = id.uuid.0
        return palette[Int(firstByte) % palette.count]
    }
}
