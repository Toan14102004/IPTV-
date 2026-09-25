//
//  XtreamDisclaimerDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// Legal notice shown before a profile's content opens.
struct XtreamDisclaimerDialogView: View {
    let onCancel: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("i")
                .font(FontFamily.Poppins.medium.font(size: 42))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Asset.Color.pinkAccent.color))

            Text("xtream_disclaimer_title".localized)
                .font(FontFamily.Poppins.medium.font(size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, Layout.Spacing.m)

            VStack(alignment: .leading, spacing: 0) {
                Text("xtream_disclaimer_intro".localized)
                    .font(FontFamily.Poppins.regular.font(size: 13))
                Text("xtream_disclaimer_body".localized)
                    .font(FontFamily.Poppins.regular.font(size: 11))
                    .padding(.top, 10)
                Text("xtream_disclaimer_confirm".localized)
                    .font(FontFamily.Poppins.regular.font(size: 11))
                    .padding(.top, 14)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 14)

            HStack(spacing: 9) {
                button("cancel".localized, font: FontFamily.Poppins.regular, color: Asset.Color.buttonNeutral.color, action: onCancel)
                button("continue".localized, font: FontFamily.Poppins.medium, color: Asset.Color.brandRedButton.color, action: onContinue)
            }
            .padding(.top, 18)
        }
        .padding(20)
        .padding(.top, Layout.Spacing.xs)
        .frame(width: 283)
        .background(Asset.Color.dialogBackground.color)
        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.xxl))
    }

    private func button(_ title: String, font: FontConvertible, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(font.font(size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 43)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
}
