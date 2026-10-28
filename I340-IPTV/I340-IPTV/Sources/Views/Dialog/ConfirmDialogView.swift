//
//  ConfirmDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// Centered "are you sure?" dialog (Figma "popup"): outlined No and a filled destructive Yes.
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
                Button(action: onNo) {
                    Text(noTitle)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.text2, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onYes) {
                    Text(yesTitle)
                        .font(Typography.subtitleSmall)
                        .foregroundStyle(Color.text4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.roomLeave, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .padding(.horizontal, Layout.Spacing.m)
    }
}

extension Color {
    /// Dim behind blocking dialogs (delete confirmation, rename sheet).
    static let dialogDim = Color.black.opacity(0.9)
}
