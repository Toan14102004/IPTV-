//
//  PaywallProductRow.swift
//  I340_IPTV
//

import SwiftUI

/// One purchasable plan: radio, name, "auto-renewable" hint, price and period.
struct PaywallProductRow: View {
    let title: String
    let detail: String
    let price: String
    let period: String
    let isSelected: Bool
    let isMostPopular: Bool
    let onTap: () -> Void

    private let red = Asset.Color.brandRed.color

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Layout.Spacing.sm) {
                radio

                VStack(alignment: .leading, spacing: Layout.Spacing.xxs) {
                    Text(title)
                        .font(FontFamily.Poppins.semiBold.font(size: 16))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(detail)
                        .font(FontFamily.Poppins.regular.font(size: 12))
                        .foregroundColor(isSelected ? .white : Asset.Color.textGray.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: Layout.Spacing.xxs) {
                    Text(price)
                        .font(FontFamily.Poppins.semiBold.font(size: 20))
                        .foregroundColor(isSelected ? red : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(period)
                        .font(FontFamily.Poppins.regular.font(size: 12))
                        .foregroundColor(.white)
                }
                .frame(minWidth: 88, alignment: .trailing)
            }
            .padding(.horizontal, Layout.Spacing.m)
            .frame(height: 76)
            .background(isSelected ? red.opacity(0.1) : Asset.Color.cardBackground.color)
            .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.CornerRadius.sm)
                    .stroke(isSelected ? red : Asset.Color.cardBorder.color, lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isMostPopular {
                    Text("inapp_most_popular".localized)
                        .font(FontFamily.Poppins.medium.font(size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, Layout.Spacing.s)
                        .frame(height: 24)
                        .background(red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.trailing, 20)
                        .offset(y: -14)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var radio: some View {
        Circle()
            .stroke(isSelected ? red : Asset.Color.radioBorder.color, lineWidth: 1)
            .background(Circle().fill(isSelected ? red : .clear))
            .frame(width: 20, height: 20)
            .overlay {
                if isSelected {
                    Circle().fill(Color.white).frame(width: 6, height: 6)
                }
            }
    }
}
