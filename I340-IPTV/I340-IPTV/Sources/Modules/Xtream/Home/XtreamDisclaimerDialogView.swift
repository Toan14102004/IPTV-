//
//  XtreamDisclaimerDialogView.swift
//  I340_IPTV
//

import SwiftUI

struct XtreamDisclaimerDialogView: View {
    let onCancel: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("i")
                .font(FontFamily.Poppins.medium.font(size: 30))
                .foregroundStyle(Color.text4)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.primary1))

            Text("xtream_disclaimer_title".localized)
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
                .multilineTextAlignment(.center)
                .padding(.top, Layout.Spacing.m)

            VStack(alignment: .leading, spacing: 0) {
                Text("xtream_disclaimer_intro".localized)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text1)
                Text("xtream_disclaimer_body".localized)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.text2)
                    .padding(.top, Layout.Spacing.s)
                Text("xtream_disclaimer_confirm".localized)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.text2)
                    .padding(.top, Layout.Spacing.m)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Layout.Spacing.m)

            HStack(spacing: Layout.Spacing.sm) {
                Button(action: onCancel) {
                    Text("cancel".localized)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.text2, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onContinue) {
                    Text("continue".localized)
                        .font(Typography.subtitleSmall)
                        .foregroundStyle(Color.text4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.top, Layout.Spacing.l)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, Layout.Spacing.m)
        .frame(maxWidth: .infinity)
        .background(Color.background1, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, Layout.Spacing.m)
    }
}
