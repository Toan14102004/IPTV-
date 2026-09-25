//
//  GradientButtonStyle.swift
//  I340_IPTV
//

import SwiftUI

/// Horizontal red gradient used by the primary buttons of dialogs and sheets.
struct GradientButtonStyle: ButtonStyle {
    var colors: [Color] = [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color, Asset.Color.brandRedDark.color]
    var cornerRadius: CGFloat = Layout.CornerRadius.sm

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == GradientButtonStyle {
    static func gradient(colors: [Color] = [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color, Asset.Color.brandRedDark.color],
                         cornerRadius: CGFloat = Layout.CornerRadius.sm) -> GradientButtonStyle {
        GradientButtonStyle(colors: colors, cornerRadius: cornerRadius)
    }
}
