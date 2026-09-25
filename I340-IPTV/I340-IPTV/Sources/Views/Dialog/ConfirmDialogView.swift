//
//  ConfirmDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// Centered "are you sure?" dialog with a muted No and a gradient Yes button.
/// Present it with `.popup(item:)` and `params.centerPopup().backgroundColor(.dialogDim)`.
struct ConfirmDialogView: View {
    let title: String
    let message: String
    let noTitle: String
    let yesTitle: String
    let onNo: () -> Void
    let onYes: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(FontFamily.Poppins.semiBold.font(size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 29)

            Text(message)
                .font(FontFamily.Poppins.regular.font(size: 12))
                .foregroundColor(Asset.Color.textGray.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Spacer(minLength: 0)

            HStack(spacing: Layout.Spacing.s) {
                Button(action: onNo) {
                    Text(noTitle)
                        .font(FontFamily.Poppins.regular.font(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
                }

                Button(action: onYes) {
                    Text(yesTitle)
                        .font(FontFamily.Poppins.semiBold.font(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.gradient(colors: [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color]))
            }
            .padding(.bottom, 29)
        }
        .padding(.horizontal, 20)
        .frame(width: 307, height: 184)
        .background(Asset.Color.sheetSurface.color)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color.white.opacity(0.05), radius: 10, x: 0, y: -1)
    }
}

extension Color {
    /// Dim behind blocking dialogs (delete confirmation, rename sheet).
    static let dialogDim = Color.black.opacity(0.9)
}
