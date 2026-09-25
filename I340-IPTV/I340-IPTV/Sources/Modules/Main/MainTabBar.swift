//
//  MainTabBar.swift
//  I340_IPTV
//

import SwiftUI
import UIKit

/// Bottom bar with the Playlist / Xtream tabs and the center "+" button.
struct MainTabBar: View {
    let selectedTab: MainView.Tab
    let playlistTitle: String
    let xtreamTitle: String
    let onSelect: (MainView.Tab) -> Void
    let onAdd: () -> Void

    private let inactiveColor = Asset.Color.dividerGray.color

    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                tabItem(.playlist, title: playlistTitle, icon: Asset.Icon.icMainTabPlaylist)
                Spacer(minLength: 0)
                tabItem(.xtream, title: xtreamTitle, icon: Asset.Icon.icMainTabXtream)
            }
            .padding(.horizontal, 50)

            addButton
        }
        .padding(.top, Layout.Spacing.sm)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background(
            TopRoundedShape(radius: Layout.CornerRadius.xl)
                .fill(Color.black)
                .overlay(TopRoundedShape(radius: Layout.CornerRadius.xl).stroke(Asset.Color.tabBarBorder.color, lineWidth: 1))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(_ tab: MainView.Tab, title: String, icon: ImageAsset) -> some View {
        let isSelected = selectedTab == tab
        let color = isSelected ? Color.brand : inactiveColor
        // The selected Playlist icon is a full-color asset, all others are tinted.
        let keepsOriginalColors = isSelected && tab == .playlist

        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: Layout.Spacing.xs) {
                icon.image
                    .renderingMode(keepsOriginalColors ? .original : .template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(FontFamily.Poppins.medium.font(size: 10))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(height: 12)
            }
            .frame(width: 60, height: 40)
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
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color, Asset.Color.brandRedDark.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Asset.Color.brandRedGlow.color.opacity(0.65), radius: 8)
        }
        .buttonStyle(.plain)
    }
}
