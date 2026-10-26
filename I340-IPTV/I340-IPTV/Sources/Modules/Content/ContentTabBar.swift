//
//  ContentTabBar.swift
//  I340_IPTV
//

import SwiftUI

struct ContentTabBar: View {
    let selectedTab: ContentView.Tab
    let title: (ContentView.Tab) -> String
    let onSelect: (ContentView.Tab) -> Void
    let onAdd: () -> Void

    @Namespace private var namespace
    var body: some View {
        HStack(spacing: 0) {
            tabItem(.playlist)
            Spacer(minLength: 0)
            tabItem(.hub)
            Spacer(minLength: 0)
            addButton
            Spacer(minLength: 0)
            tabItem(.xtream)
            Spacer(minLength: 0)
            tabItem(.settings)
        }
        .padding(.horizontal, Layout.Spacing.l)
        .padding(.vertical, Layout.Spacing.s)
        // Surface/Nav renders as opaque #F8F8F8 in the design (its 60% fill sits on a background blur).
        .background(Color(hex: 0xF8F8F8), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.neutralStroke, lineWidth: 1))
        .shadow(.nav)
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.bottom, Layout.Spacing.xs)
    }
   
    private func select(_ tab: ContentView.Tab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { onSelect(tab) }
    }

    private func tabItem(_ tab: ContentView.Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            select(tab)
        } label: {
            VStack(spacing: Layout.Spacing.xs) {
                tab.icon.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(isSelected ? Color.white : Color.text3)
                    .frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)

                Text(title(tab))
                    .font(Typography.captionMedium)
                    .foregroundStyle(isSelected ? Color.primary1 : Color.text3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(minWidth: 40)
            .background(alignment: .top) {
                if isSelected {
                    Circle()
                        .fill(Color.primary1)
                        .frame(width: 40, height: 40)
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Asset.Icon.icMainTabAdd.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .frame(width: 52, height: 52)
                .background(LinearGradient.primaryLinear, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private extension ContentView.Tab {
    var icon: ImageAsset {
        switch self {
        case .playlist: Asset.Icon.icMainTabPlaylist
        case .hub: Asset.Icon.icMainTabHub
        case .xtream: Asset.Icon.icMainTabXtream
        case .settings: Asset.Icon.icMainTabSetting
        }
    }
}
