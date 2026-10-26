//
//  AppColors.swift
//  I340_IPTV
//

import SwiftUI

/// Semantic shortcuts for colors of `Color.xcassets`.
extension Color {
    /// Brand red, used for primary buttons, selected tab, loading indicator.
    static let brand = Asset.Color.brandRed.color
    /// Card / popup surface on the dark canvas.
    static let surface = Asset.Color.surfaceDark.color
    /// Secondary (muted) text.
    static let textSecondary = Asset.Color.textOnSurface.color
}

// MARK: - Figma tokens (light screens)

/// Paint styles of the Figma "IPTV" file, used by the light screens. Names follow the Figma
/// style names (`Text/Color 1` → `text1`).
extension Color {
    // Background
    /// Background/Color 1
    static let background1 = Color(hex: 0xFFFFFF)

    // Primary
    /// Primary/Color 1
    static let primary1 = Color(hex: 0x2468F2)
    /// Primary/Color 2
    static let primary2 = Color(hex: 0xE0EAFF)

    // Text
    /// Text/Color 1
    static let text1 = Color(hex: 0x172033)
    /// Text/Color 2
    static let text2 = Color(hex: 0x77777B)
    /// Text/Color 3
    static let text3 = Color(hex: 0xABB4C1)
    /// Text/Color 4
    static let text4 = Color(hex: 0xFFFFFF)

    // Surface
    /// Surface/Color 1
    static let surface1 = Color(hex: 0xF7F7F7)
    /// Surface/Color 2
    static let surface2 = Color(hex: 0xF2F2F2, opacity: 0.6)
    /// Surface/Nav (60% fill meant to sit on a background blur).
    static let surfaceNav = Color(hex: 0xF2F2F2, opacity: 0.6)

    // Neutral
    /// Neutral/Color 1
    static let neutral1 = Color(hex: 0xF2F2F2)
    /// Neutral/Stroke
    static let neutralStroke = Color(hex: 0xFFFFFF)
    /// Light outline used by the Language rows (not a Figma style).
    static let border1 = Color(hex: 0xE8ECEF)

    // Linear
    /// Linear/Color 1 (solid; also the native ad CTA color)
    static let linear1 = Color(hex: 0x2964D0)

    // Opacity
    /// Opacity/Color 1: black 20%
    static let opacity1 = Color.black.opacity(0.2)
    /// Opacity/Color 2: white 20%
    static let opacity2 = Color.white.opacity(0.2)

    // Accent
    /// Accent/Color 1 (green)
    static let accent1 = Color(hex: 0x22C55E)
    /// Accent/Color 2 (red)
    static let accent2 = Color(hex: 0xFF4136)
    /// Accent/Color 3 (yellow)
    static let accent3 = Color(hex: 0xFFC518)
}

extension LinearGradient {
    /// Primary/Linear: light blue at the bottom fading to Primary/Color 1 at the top.
    static let primaryLinear = LinearGradient(
        colors: [Color(hex: 0x4AA7FF), .primary1],
        startPoint: .bottom,
        endPoint: .top
    )

    /// Linear/Color 2: #3462D5 at 20% on top fading to transparent at the bottom.
    static let linear2 = LinearGradient(
        colors: [Color(hex: 0x3462D5, opacity: 0.2), Color(hex: 0x3462D5, opacity: 0)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Figma effect styles

/// Drop shadows of the Figma effect styles. Figma's blur is twice SwiftUI's `radius`.
enum AppShadow {
    /// Nav: 0 -2, blur 8, black 4%
    case nav
    /// 1: 0 2, blur 6, black 10%
    case level1
    /// 2: 0 4, blur 12, black 4%
    case level2
    /// Shadow/Text field: 0 4, blur 12, black 6%
    case textField
    /// Shadow/Card: 0 2, blur 12, black 8%
    case card

    fileprivate var values: (opacity: Double, blur: CGFloat, y: CGFloat) {
        switch self {
        case .nav: (0.04, 8, -2)
        case .level1: (0.10, 6, 2)
        case .level2: (0.04, 12, 4)
        case .textField: (0.06, 12, 4)
        case .card: (0.08, 12, 2)
        }
    }
}

extension View {
    func shadow(_ style: AppShadow) -> some View {
        let v = style.values
        return shadow(color: .black.opacity(v.opacity), radius: v.blur / 2, x: 0, y: v.y)
    }
}
