//
//  HeaderActionButtons.swift
//  I340_IPTV
//

import SwiftUI

/// Premium crown (hidden for subscribers), settings and help icons shown on the main screens.
struct HeaderActionButtons: View {
    let isSubscribed: Bool
    let onPremium: () -> Void
    let onSettings: () -> Void
    let onHelp: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            if !isSubscribed {
                button(Asset.Icon.icPremiumMain, action: onPremium)
            }
            button(Asset.Icon.icSetting, action: onSettings)
            button(Asset.Icon.icHelpMain, action: onHelp)
        }
    }

    private func button(_ icon: ImageAsset, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon.image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
