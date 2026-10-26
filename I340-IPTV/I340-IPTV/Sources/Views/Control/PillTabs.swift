//
//  PillTabs.swift
//  I340_IPTV
//

import SwiftUI

/// Two or more tabs in a light capsule; the selected one is a filled primary capsule (Figma "Favorite").
struct PillTabs: View {
    let titles: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(titles.indices, id: \.self) { index in
                let isSelected = index == selectedIndex
                Button { onSelect(index) } label: {
                    Text(titles[index])
                        .font(Typography.labelLarge)
                        .foregroundStyle(isSelected ? Color.text4 : Color.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(isSelected ? Color.primary1 : Color.clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.Spacing.xs)
        .frame(height: 40)
        .background(Color.surface2, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.neutralStroke, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
    }
}
