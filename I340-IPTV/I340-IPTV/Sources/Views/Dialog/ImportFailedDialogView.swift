//
//  ImportFailedDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// Shown when an Xtream account could not be added.
struct ImportFailedDialogView: View {
    let title: String
    let message: String
    let closeTitle: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Asset.Image.Movies.icFailedAddXtream.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 49)

                Text(title)
                    .font(FontFamily.Poppins.medium.font(size: 24))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.top, 20)

                Text(message)
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(Asset.Color.textTertiary.color)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 6)
                    .padding(.top, Layout.Spacing.s)

                Spacer(minLength: 10)

                Button(action: onClose) {
                    Text(closeTitle)
                        .font(FontFamily.Poppins.medium.font(size: 24))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.gradient(colors: [Asset.Color.brandRedDeep.color, Asset.Color.brandRed.color, Asset.Color.brandRedDeep.color], cornerRadius: 25))
                .padding(.bottom, Layout.Spacing.l)
            }
            .padding(.horizontal, 18)
            .frame(width: 282, height: 307)
            .background(Asset.Color.dialogBackground.color)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
    }
}
