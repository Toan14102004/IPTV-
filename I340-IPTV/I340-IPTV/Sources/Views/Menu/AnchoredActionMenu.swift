//
//  AnchoredActionMenu.swift
//  I340_IPTV
//

import SwiftUI

struct ActionMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let action: () -> Void
}

/// Preference that collects the bounds of every "more" button, keyed by the id of its row.
struct ActionMenuAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Marks the view a menu opened for `id` is anchored to.
    func actionMenuAnchor(id: String) -> some View {
        anchorPreference(key: ActionMenuAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// Shows a small dark menu next to the anchor of `activeID`; tapping elsewhere calls `onDismiss`.
    func actionMenu(activeID: String?, items: [ActionMenuItem], onDismiss: @escaping () -> Void) -> some View {
        overlayPreferenceValue(ActionMenuAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if let activeID, let anchor = anchors[activeID] {
                    let rect = proxy[anchor]
                    let size = CGSize(width: 149, height: CGFloat(items.count) * 52 + CGFloat(max(items.count - 1, 0)))
                    let trailing = min(proxy.size.width - 16, rect.maxX + 4)
                    let x = max(16, trailing - size.width)
                    let y = min(proxy.size.height - size.height - 16, rect.maxY + 8)

                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onDismiss)

                        ActionMenuView(items: items, onSelect: onDismiss)
                            .frame(width: size.width, height: size.height)
                            .offset(x: x, y: y)
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                }
            }
            .animation(.easeOut(duration: 0.16), value: activeID)
        }
    }
}

private struct ActionMenuView: View {
    let items: [ActionMenuItem]
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Asset.Color.cardBorder.color)
                        .frame(height: 1)
                }
                Button {
                    onSelect()
                    item.action()
                } label: {
                    HStack(spacing: Layout.Spacing.sm) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                        Text(item.title)
                            .font(FontFamily.Poppins.regular.font(size: 14))
                            .foregroundColor(.white)
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .background(Asset.Color.surfaceDarkest.color)
        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: Layout.CornerRadius.large).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
        .shadow(color: Asset.Color.borderMuted.color.opacity(0.25), radius: 3, x: 2, y: 2)
    }
}
