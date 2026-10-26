//
//  AppDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// Light dialog of the new design (Figma "popup"): optional illustration, title, message and an
/// outlined secondary + filled primary button. The close button shows when `onClose` is set.
struct AppDialogView: View {
    var image: ImageAsset?
    /// Illustration height; icon-sized artwork (e.g. leave room) uses a smaller one.
    var imageHeight: CGFloat = 144
    var imageSpacing: CGFloat = Layout.Spacing.l
    let title: String
    let message: String
    let secondaryTitle: String
    let primaryTitle: String
    let onSecondary: () -> Void
    let onPrimary: () -> Void
    var onClose: (() -> Void)?
    /// Outline / text color of the secondary button and fill of the primary one.
    var secondaryColor: Color = .primary1
    var primaryColor: Color = .primary1

    var body: some View {
        VStack(spacing: 0) {
            if let image {
                image.image
                    .resizable()
                    .scaledToFit()
                    .frame(height: imageHeight)
                    .padding(.bottom, imageSpacing)
            }

            VStack(spacing: Layout.Spacing.xs) {
                Text(title)
                    .font(Typography.subtitleMedium)
                    .foregroundStyle(Color.text1)

                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.text2)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Layout.Spacing.m)

            HStack(spacing: Layout.Spacing.sm) {
                Button(action: onSecondary) {
                    Text(secondaryTitle)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(secondaryColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(secondaryColor, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onPrimary) {
                    Text(primaryTitle)
                        .font(Typography.subtitleSmall)
                        .foregroundStyle(Color.text4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(primaryColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.top, Layout.Spacing.l)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.background1, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if let onClose {
                Button(action: onClose) {
                    Asset.Icon.icDialogClose.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text2)
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 5)
                .padding(.trailing, 7)
            }
        }
        .padding(.horizontal, Layout.Spacing.m)
    }
}

#Preview {
    AppDialogView(
        image: Asset.Image.imgInvalidSource,
        title: "Invalid Playlist Source",
        message: "We couldn’t find a valid playlist or stream. Please check your information and try again.",
        secondaryTitle: "Cancel",
        primaryTitle: "Try Again",
        onSecondary: {},
        onPrimary: {},
        onClose: {}
    )
    .padding(.vertical)
    .background(Color.black.opacity(0.3))
}
