//
//  SegmentedTabs.swift
//  I340_IPTV
//

import SwiftUI

/// Pill-shaped tab switcher: a white capsule slides behind the selected title.
struct SegmentedTabs: View {
    let titles: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { onSelect(index) }
                } label: {
                    Text(titles[index])
                        .font(FontFamily.Poppins.medium.font(size: 14))
                        .foregroundColor(index == selectedIndex ? .black : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if index == selectedIndex {
                                Capsule()
                                    .fill(Color.white)
                                    .padding(Layout.Spacing.xs)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 48)
        .background(Asset.Color.fieldBackground.color)
        .clipShape(Capsule())
    }
}
