import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AuthFieldBg" asset catalog color resource.
    static let authFieldBg = DeveloperToolsSupport.ColorResource(name: "AuthFieldBg", bundle: resourceBundle)

    /// The "AvatarBlue" asset catalog color resource.
    static let avatarBlue = DeveloperToolsSupport.ColorResource(name: "AvatarBlue", bundle: resourceBundle)

    /// The "AvatarGreen" asset catalog color resource.
    static let avatarGreen = DeveloperToolsSupport.ColorResource(name: "AvatarGreen", bundle: resourceBundle)

    /// The "AvatarOrange" asset catalog color resource.
    static let avatarOrange = DeveloperToolsSupport.ColorResource(name: "AvatarOrange", bundle: resourceBundle)

    /// The "AvatarPink" asset catalog color resource.
    static let avatarPink = DeveloperToolsSupport.ColorResource(name: "AvatarPink", bundle: resourceBundle)

    /// The "AvatarTintA" asset catalog color resource.
    static let avatarTintA = DeveloperToolsSupport.ColorResource(name: "AvatarTintA", bundle: resourceBundle)

    /// The "AvatarTintB" asset catalog color resource.
    static let avatarTintB = DeveloperToolsSupport.ColorResource(name: "AvatarTintB", bundle: resourceBundle)

    /// The "AvatarTintC" asset catalog color resource.
    static let avatarTintC = DeveloperToolsSupport.ColorResource(name: "AvatarTintC", bundle: resourceBundle)

    /// The "AvatarTintD" asset catalog color resource.
    static let avatarTintD = DeveloperToolsSupport.ColorResource(name: "AvatarTintD", bundle: resourceBundle)

    /// The "AvatarTintE" asset catalog color resource.
    static let avatarTintE = DeveloperToolsSupport.ColorResource(name: "AvatarTintE", bundle: resourceBundle)

    /// The "BalanceBlue" asset catalog color resource.
    static let balanceBlue = DeveloperToolsSupport.ColorResource(name: "BalanceBlue", bundle: resourceBundle)

    /// The "BalanceNavy" asset catalog color resource.
    static let balanceNavy = DeveloperToolsSupport.ColorResource(name: "BalanceNavy", bundle: resourceBundle)

    /// The "BgTop" asset catalog color resource.
    static let bgTop = DeveloperToolsSupport.ColorResource(name: "BgTop", bundle: resourceBundle)

    /// The "CardHairline" asset catalog color resource.
    static let cardHairline = DeveloperToolsSupport.ColorResource(name: "CardHairline", bundle: resourceBundle)

    /// The "ChipBlue" asset catalog color resource.
    static let chipBlue = DeveloperToolsSupport.ColorResource(name: "ChipBlue", bundle: resourceBundle)

    /// The "DotInactive" asset catalog color resource.
    static let dotInactive = DeveloperToolsSupport.ColorResource(name: "DotInactive", bundle: resourceBundle)

    /// The "GoldAccent" asset catalog color resource.
    static let goldAccent = DeveloperToolsSupport.ColorResource(name: "GoldAccent", bundle: resourceBundle)

    /// The "IconTintBg" asset catalog color resource.
    static let iconTintBg = DeveloperToolsSupport.ColorResource(name: "IconTintBg", bundle: resourceBundle)

    /// The "Negative" asset catalog color resource.
    static let negative = DeveloperToolsSupport.ColorResource(name: "Negative", bundle: resourceBundle)

    /// The "PandaBlue" asset catalog color resource.
    static let pandaBlue = DeveloperToolsSupport.ColorResource(name: "PandaBlue", bundle: resourceBundle)

    /// The "Positive" asset catalog color resource.
    static let positive = DeveloperToolsSupport.ColorResource(name: "Positive", bundle: resourceBundle)

    /// The "TextPrimary" asset catalog color resource.
    static let textPrimary = DeveloperToolsSupport.ColorResource(name: "TextPrimary", bundle: resourceBundle)

    /// The "TextSecondary" asset catalog color resource.
    static let textSecondary = DeveloperToolsSupport.ColorResource(name: "TextSecondary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "panda_logo" asset catalog image resource.
    static let pandaLogo = DeveloperToolsSupport.ImageResource(name: "panda_logo", bundle: resourceBundle)

    /// The "pandas_group" asset catalog image resource.
    static let pandasGroup = DeveloperToolsSupport.ImageResource(name: "pandas_group", bundle: resourceBundle)

    /// The "pandas_highfive" asset catalog image resource.
    static let pandasHighfive = DeveloperToolsSupport.ImageResource(name: "pandas_highfive", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AuthFieldBg" asset catalog color.
    static var authFieldBg: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .authFieldBg)
#else
        .init()
#endif
    }

    /// The "AvatarBlue" asset catalog color.
    static var avatarBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarBlue)
#else
        .init()
#endif
    }

    /// The "AvatarGreen" asset catalog color.
    static var avatarGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarGreen)
#else
        .init()
#endif
    }

    /// The "AvatarOrange" asset catalog color.
    static var avatarOrange: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarOrange)
#else
        .init()
#endif
    }

    /// The "AvatarPink" asset catalog color.
    static var avatarPink: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarPink)
#else
        .init()
#endif
    }

    /// The "AvatarTintA" asset catalog color.
    static var avatarTintA: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarTintA)
#else
        .init()
#endif
    }

    /// The "AvatarTintB" asset catalog color.
    static var avatarTintB: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarTintB)
#else
        .init()
#endif
    }

    /// The "AvatarTintC" asset catalog color.
    static var avatarTintC: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarTintC)
#else
        .init()
#endif
    }

    /// The "AvatarTintD" asset catalog color.
    static var avatarTintD: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarTintD)
#else
        .init()
#endif
    }

    /// The "AvatarTintE" asset catalog color.
    static var avatarTintE: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatarTintE)
#else
        .init()
#endif
    }

    /// The "BalanceBlue" asset catalog color.
    static var balanceBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .balanceBlue)
#else
        .init()
#endif
    }

    /// The "BalanceNavy" asset catalog color.
    static var balanceNavy: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .balanceNavy)
#else
        .init()
#endif
    }

    /// The "BgTop" asset catalog color.
    static var bgTop: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bgTop)
#else
        .init()
#endif
    }

    /// The "CardHairline" asset catalog color.
    static var cardHairline: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cardHairline)
#else
        .init()
#endif
    }

    /// The "ChipBlue" asset catalog color.
    static var chipBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chipBlue)
#else
        .init()
#endif
    }

    /// The "DotInactive" asset catalog color.
    static var dotInactive: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dotInactive)
#else
        .init()
#endif
    }

    /// The "GoldAccent" asset catalog color.
    static var goldAccent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goldAccent)
#else
        .init()
#endif
    }

    /// The "IconTintBg" asset catalog color.
    static var iconTintBg: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .iconTintBg)
#else
        .init()
#endif
    }

    /// The "Negative" asset catalog color.
    static var negative: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .negative)
#else
        .init()
#endif
    }

    /// The "PandaBlue" asset catalog color.
    static var pandaBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pandaBlue)
#else
        .init()
#endif
    }

    /// The "Positive" asset catalog color.
    static var positive: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .positive)
#else
        .init()
#endif
    }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textSecondary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AuthFieldBg" asset catalog color.
    static var authFieldBg: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .authFieldBg)
#else
        .init()
#endif
    }

    /// The "AvatarBlue" asset catalog color.
    static var avatarBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarBlue)
#else
        .init()
#endif
    }

    /// The "AvatarGreen" asset catalog color.
    static var avatarGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarGreen)
#else
        .init()
#endif
    }

    /// The "AvatarOrange" asset catalog color.
    static var avatarOrange: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarOrange)
#else
        .init()
#endif
    }

    /// The "AvatarPink" asset catalog color.
    static var avatarPink: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarPink)
#else
        .init()
#endif
    }

    /// The "AvatarTintA" asset catalog color.
    static var avatarTintA: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarTintA)
#else
        .init()
#endif
    }

    /// The "AvatarTintB" asset catalog color.
    static var avatarTintB: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarTintB)
#else
        .init()
#endif
    }

    /// The "AvatarTintC" asset catalog color.
    static var avatarTintC: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarTintC)
#else
        .init()
#endif
    }

    /// The "AvatarTintD" asset catalog color.
    static var avatarTintD: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarTintD)
#else
        .init()
#endif
    }

    /// The "AvatarTintE" asset catalog color.
    static var avatarTintE: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .avatarTintE)
#else
        .init()
#endif
    }

    /// The "BalanceBlue" asset catalog color.
    static var balanceBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .balanceBlue)
#else
        .init()
#endif
    }

    /// The "BalanceNavy" asset catalog color.
    static var balanceNavy: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .balanceNavy)
#else
        .init()
#endif
    }

    /// The "BgTop" asset catalog color.
    static var bgTop: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bgTop)
#else
        .init()
#endif
    }

    /// The "CardHairline" asset catalog color.
    static var cardHairline: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .cardHairline)
#else
        .init()
#endif
    }

    /// The "ChipBlue" asset catalog color.
    static var chipBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .chipBlue)
#else
        .init()
#endif
    }

    /// The "DotInactive" asset catalog color.
    static var dotInactive: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .dotInactive)
#else
        .init()
#endif
    }

    /// The "GoldAccent" asset catalog color.
    static var goldAccent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .goldAccent)
#else
        .init()
#endif
    }

    /// The "IconTintBg" asset catalog color.
    static var iconTintBg: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .iconTintBg)
#else
        .init()
#endif
    }

    /// The "Negative" asset catalog color.
    static var negative: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .negative)
#else
        .init()
#endif
    }

    /// The "PandaBlue" asset catalog color.
    static var pandaBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .pandaBlue)
#else
        .init()
#endif
    }

    /// The "Positive" asset catalog color.
    static var positive: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .positive)
#else
        .init()
#endif
    }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textSecondary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AuthFieldBg" asset catalog color.
    static var authFieldBg: SwiftUI.Color { .init(.authFieldBg) }

    /// The "AvatarBlue" asset catalog color.
    static var avatarBlue: SwiftUI.Color { .init(.avatarBlue) }

    /// The "AvatarGreen" asset catalog color.
    static var avatarGreen: SwiftUI.Color { .init(.avatarGreen) }

    /// The "AvatarOrange" asset catalog color.
    static var avatarOrange: SwiftUI.Color { .init(.avatarOrange) }

    /// The "AvatarPink" asset catalog color.
    static var avatarPink: SwiftUI.Color { .init(.avatarPink) }

    /// The "AvatarTintA" asset catalog color.
    static var avatarTintA: SwiftUI.Color { .init(.avatarTintA) }

    /// The "AvatarTintB" asset catalog color.
    static var avatarTintB: SwiftUI.Color { .init(.avatarTintB) }

    /// The "AvatarTintC" asset catalog color.
    static var avatarTintC: SwiftUI.Color { .init(.avatarTintC) }

    /// The "AvatarTintD" asset catalog color.
    static var avatarTintD: SwiftUI.Color { .init(.avatarTintD) }

    /// The "AvatarTintE" asset catalog color.
    static var avatarTintE: SwiftUI.Color { .init(.avatarTintE) }

    /// The "BalanceBlue" asset catalog color.
    static var balanceBlue: SwiftUI.Color { .init(.balanceBlue) }

    /// The "BalanceNavy" asset catalog color.
    static var balanceNavy: SwiftUI.Color { .init(.balanceNavy) }

    /// The "BgTop" asset catalog color.
    static var bgTop: SwiftUI.Color { .init(.bgTop) }

    /// The "CardHairline" asset catalog color.
    static var cardHairline: SwiftUI.Color { .init(.cardHairline) }

    /// The "ChipBlue" asset catalog color.
    static var chipBlue: SwiftUI.Color { .init(.chipBlue) }

    /// The "DotInactive" asset catalog color.
    static var dotInactive: SwiftUI.Color { .init(.dotInactive) }

    /// The "GoldAccent" asset catalog color.
    static var goldAccent: SwiftUI.Color { .init(.goldAccent) }

    /// The "IconTintBg" asset catalog color.
    static var iconTintBg: SwiftUI.Color { .init(.iconTintBg) }

    /// The "Negative" asset catalog color.
    static var negative: SwiftUI.Color { .init(.negative) }

    /// The "PandaBlue" asset catalog color.
    static var pandaBlue: SwiftUI.Color { .init(.pandaBlue) }

    /// The "Positive" asset catalog color.
    static var positive: SwiftUI.Color { .init(.positive) }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: SwiftUI.Color { .init(.textSecondary) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AuthFieldBg" asset catalog color.
    static var authFieldBg: SwiftUI.Color { .init(.authFieldBg) }

    /// The "AvatarBlue" asset catalog color.
    static var avatarBlue: SwiftUI.Color { .init(.avatarBlue) }

    /// The "AvatarGreen" asset catalog color.
    static var avatarGreen: SwiftUI.Color { .init(.avatarGreen) }

    /// The "AvatarOrange" asset catalog color.
    static var avatarOrange: SwiftUI.Color { .init(.avatarOrange) }

    /// The "AvatarPink" asset catalog color.
    static var avatarPink: SwiftUI.Color { .init(.avatarPink) }

    /// The "AvatarTintA" asset catalog color.
    static var avatarTintA: SwiftUI.Color { .init(.avatarTintA) }

    /// The "AvatarTintB" asset catalog color.
    static var avatarTintB: SwiftUI.Color { .init(.avatarTintB) }

    /// The "AvatarTintC" asset catalog color.
    static var avatarTintC: SwiftUI.Color { .init(.avatarTintC) }

    /// The "AvatarTintD" asset catalog color.
    static var avatarTintD: SwiftUI.Color { .init(.avatarTintD) }

    /// The "AvatarTintE" asset catalog color.
    static var avatarTintE: SwiftUI.Color { .init(.avatarTintE) }

    /// The "BalanceBlue" asset catalog color.
    static var balanceBlue: SwiftUI.Color { .init(.balanceBlue) }

    /// The "BalanceNavy" asset catalog color.
    static var balanceNavy: SwiftUI.Color { .init(.balanceNavy) }

    /// The "BgTop" asset catalog color.
    static var bgTop: SwiftUI.Color { .init(.bgTop) }

    /// The "CardHairline" asset catalog color.
    static var cardHairline: SwiftUI.Color { .init(.cardHairline) }

    /// The "ChipBlue" asset catalog color.
    static var chipBlue: SwiftUI.Color { .init(.chipBlue) }

    /// The "DotInactive" asset catalog color.
    static var dotInactive: SwiftUI.Color { .init(.dotInactive) }

    /// The "GoldAccent" asset catalog color.
    static var goldAccent: SwiftUI.Color { .init(.goldAccent) }

    /// The "IconTintBg" asset catalog color.
    static var iconTintBg: SwiftUI.Color { .init(.iconTintBg) }

    /// The "Negative" asset catalog color.
    static var negative: SwiftUI.Color { .init(.negative) }

    /// The "PandaBlue" asset catalog color.
    static var pandaBlue: SwiftUI.Color { .init(.pandaBlue) }

    /// The "Positive" asset catalog color.
    static var positive: SwiftUI.Color { .init(.positive) }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: SwiftUI.Color { .init(.textSecondary) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "panda_logo" asset catalog image.
    static var pandaLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pandaLogo)
#else
        .init()
#endif
    }

    /// The "pandas_group" asset catalog image.
    static var pandasGroup: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pandasGroup)
#else
        .init()
#endif
    }

    /// The "pandas_highfive" asset catalog image.
    static var pandasHighfive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pandasHighfive)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "panda_logo" asset catalog image.
    static var pandaLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pandaLogo)
#else
        .init()
#endif
    }

    /// The "pandas_group" asset catalog image.
    static var pandasGroup: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pandasGroup)
#else
        .init()
#endif
    }

    /// The "pandas_highfive" asset catalog image.
    static var pandasHighfive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pandasHighfive)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

