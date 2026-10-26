//
//  PaywallProductRow.swift
//  I340_IPTV
//

import SwiftUI

struct PaywallProductRow: View {
    let title: String
    let detail: String
    let price: String
    let period: String
    let isSelected: Bool
    let isMostPopular: Bool
    let onTap: () -> Void

    /// Outline of the unselected cards and radios (no Figma token).
    private let idleStroke = Color(hex: 0xD8D4D4)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Layout.Spacing.sm) {
                radio

                VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                    Text(title)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.text1)
                    Text(detail)
                        .font(Typography.labelSmall)
                        .foregroundStyle(secondaryColor)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.text1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(period)
                        .font(Typography.labelSmall)
                        .foregroundStyle(secondaryColor)
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .frame(height: 73)
            .background(
                isSelected ? Color.primary2 : Color.white.opacity(0.8),
                in: RoundedRectangle(cornerRadius: Layout.CornerRadius.large)
            )
            .overlay(border)
            .overlay(alignment: .topTrailing) {
                if isMostPopular {
                    mostPopularTag
                        .padding(.trailing, Layout.Spacing.sm)
                        .offset(y: -12)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var secondaryColor: Color {
        isSelected ? Color.text1 : Color.text2
    }

    @ViewBuilder
    private var border: some View {
        let shape = RoundedRectangle(cornerRadius: Layout.CornerRadius.large)
        if isSelected {
            shape.strokeBorder(LinearGradient.primaryLinear, lineWidth: 1)
        } else {
            shape.strokeBorder(idleStroke, lineWidth: 1)
        }
    }

    private var radio: some View {
        Circle()
            .strokeBorder(isSelected ? Color.primary1 : idleStroke, lineWidth: 1)
            .overlay {
                if isSelected {
                    Circle()
                        .fill(Color.primary1)
                        .frame(width: 10, height: 10)
                }
            }
            .frame(width: 16, height: 16)
    }

    private var mostPopularTag: some View {
        Text("inapp_most_popular".localized)
            .font(Typography.captionLarge)
            .foregroundStyle(Color.text1)
            .padding(.horizontal, Layout.Spacing.s)
            .frame(height: 24)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFCF5CD), Color(hex: 0xFFCF26)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
    }
}
