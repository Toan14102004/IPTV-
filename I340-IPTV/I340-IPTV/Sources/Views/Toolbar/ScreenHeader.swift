//
//  ScreenHeader.swift
//  I340_IPTV
//

import SwiftUI

/// Header of the light screens (Figma "Button/Title"): optional back button and title on the
/// left, favorite / help / premium circle buttons on the right. A nil action hides its button.
struct ScreenHeader: View {
    let title: String
    var onBack: (() -> Void)?
    var onFavorite: (() -> Void)?
    var onHelp: (() -> Void)?
    var onPremium: (() -> Void)?
    /// Red "leave the room" button, shown in the place of the crown.
    var onLeave: (() -> Void)?

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            if let onBack {
                circleButton(action: onBack) {
                    Asset.Icon.icArrowLeft.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text1)
                }
            }

            Text(title)
                .font(FontFamily.Poppins.bold.font(size: 20))
                .foregroundStyle(Color.text1)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            HStack(spacing: Layout.Spacing.s) {
                if let onFavorite {
                    circleButton(action: onFavorite) { tinted(Asset.Icon.icHeaderFavorite) }
                }
                if let onHelp {
                    circleButton(action: onHelp) { tinted(Asset.Icon.icHeaderHelp) }
                }
                if let onLeave {
                    circleButton(action: onLeave) { Asset.Icon.icRoomLeave.image.resizable().scaledToFit() }
                } else if let onPremium {
                    circleButton(action: onPremium) { Asset.Icon.icCrown.image.resizable().scaledToFit() }
                }
            }
        }
        .padding(Layout.Spacing.m)
    }

    private func tinted(_ icon: ImageAsset) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(Color.text2)
    }

    /// 24pt icon in a 34pt translucent circle with a white outline.
    private func circleButton<Icon: View>(action: @escaping () -> Void, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: action) {
            icon()
                .frame(width: 24, height: 24)
                .frame(width: 34, height: 34)
                .background(Color.surface2, in: Circle())
                .overlay(Circle().strokeBorder(Color.neutralStroke, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScreenHeader(title: "Setting", onBack: {}, onFavorite: {}, onHelp: {}, onPremium: {})
}
