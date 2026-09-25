//
//  PlaylistFavoriteView.swift
//  I340_IPTV
//

import SwiftUI

/// Channels marked as favorite across all playlists.
struct PlaylistFavoriteView: View {
    @StateObject private var viewModel: ViewModel
    @FocusState private var isSearchFocused: Bool

    init(onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        ZStack {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                searchRow
                    .padding(.top, Layout.Spacing.m)

                content
                    .padding(.top, 13)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.isSubscribed {
                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("PlaylistFavorite")
        .actionMenu(activeID: viewModel.coordinator.actionMenuID, items: menuItems, onDismiss: viewModel.closeMenu)
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case .clearAll:
                confirm(
                    message: "playlist_favorite_delete_all_message".localized(
                        fallback: "Are you sure you want to clear all favourite channels?"
                    ),
                    onYes: viewModel.confirmClearAll
                )
            case let .remove(channel):
                confirm(
                    message: "playlist_favorite_delete_channel_message".localized(
                        fallback: "Remove this channel from favourites?"
                    ),
                    onYes: { viewModel.confirmRemove(channel) }
                )
            }
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }

    private var menuItems: [ActionMenuItem] {
        guard let id = viewModel.coordinator.actionMenuID,
              let item = viewModel.items.first(where: { $0.id == id }) else { return [] }
        return viewModel.menuItems(for: item)
    }

    private func confirm(message: String, onYes: @escaping () -> Void) -> some View {
        ConfirmDialogView(
            title: "playlist_favorite_delete_title".localized(fallback: "Delete?"),
            message: message,
            noTitle: "playlist_delete_no".localized(fallback: "No"),
            yesTitle: "playlist_delete_yes".localized(fallback: "Yes"),
            onNo: viewModel.dismissAlert,
            onYes: onYes
        )
    }
}

// MARK: - Sections

private extension PlaylistFavoriteView {
    var header: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Text(viewModel.screenTitle)
                .font(FontFamily.Poppins.medium.font(size: 24))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            HeaderActionButtons(
                isSubscribed: viewModel.isSubscribed,
                onPremium: viewModel.didTapPremium,
                onSettings: viewModel.didTapSettings,
                onHelp: viewModel.didTapHelp
            )
        }
        .padding(.horizontal, Layout.Spacing.m)
    }

    var searchRow: some View {
        HStack(spacing: Layout.Spacing.sm) {
            BackButton(action: viewModel.didTapBack)
                .frame(width: 24, height: 24)

            SearchBar(
                text: $viewModel.keyword,
                placeholder: viewModel.searchPlaceholder,
                isFocused: $isSearchFocused
            )

            Button(action: viewModel.didTapClearAll) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.items.isEmpty)
            .opacity(viewModel.items.isEmpty ? 0.35 : 1)
        }
        .padding(.horizontal, Layout.Spacing.m)
    }

    @ViewBuilder
    var content: some View {
        let items = viewModel.filteredItems
        if items.isEmpty {
            VStack(spacing: Layout.Spacing.s) {
                Text(viewModel.emptyTitle)
                    .font(FontFamily.Poppins.medium.font(size: 18))
                    .foregroundColor(.white)
                Text(viewModel.emptySubtitle)
                    .font(FontFamily.Poppins.regular.font(size: 13))
                    .foregroundColor(Asset.Color.textGray.color)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Layout.Spacing.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Layout.Spacing.m) {
                    ForEach(items) { item in
                        ChannelRow(
                            channel: item.channel,
                            isFavorite: true,
                            menuAnchorID: item.id,
                            onTap: { viewModel.open(item) },
                            onFavorite: { viewModel.removeFavorite(item.channel) },
                            onMore: { viewModel.showMenu(for: item) }
                        )
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.bottom, Layout.Spacing.s)
            }
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
        }
    }
}
