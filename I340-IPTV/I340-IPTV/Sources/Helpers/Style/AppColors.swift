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
