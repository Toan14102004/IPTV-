//
//  PlaylistFavoriteView.swift
//  I340_IPTV
//

import SwiftUI

/// Favorites (Figma "Favorite"): playlists with a heart on one tab, channels on the other.
struct PlaylistFavoriteView: View {
    @StateObject private var viewModel: ViewModel

    init(onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: viewModel.screenTitle,
                    onBack: viewModel.didTapBack,
                    onPremium: viewModel.premiumAction
                )

                PillTabs(
                    titles: viewModel.tabTitles,
                    selectedIndex: viewModel.tab.rawValue,
                    onSelect: viewModel.select
                )
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.xs)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.isSubscribed {
                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("PlaylistFavorite")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case let .deletePlaylist(playlist):
                PlaylistDeleteDialog(onNo: viewModel.dismissAlert, onYes: { viewModel.delete(playlist) })
            case let .deleteChannel(channel):
                DeleteDialogView(onCancel: viewModel.dismissAlert, onDelete: { viewModel.delete(channel) })
            }
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDimLight)
        }
        .popup(item: $viewModel.coordinator.rename) { item in
            RenameSheetView(
                title: "playlist_rename_channel_title".localized(fallback: "Rename Channel"),
                placeholder: "playlist_rename_placeholder".localized(fallback: "Playlist name"),
                continueTitle: "playlist_rename_save".localized(fallback: "Save"),
                emptyNameMessage: "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank."),
                currentName: item.channel.title.isEmpty ? item.channel.url : item.channel.title,
                onClose: { viewModel.coordinator.rename = nil },
                onContinue: { viewModel.rename(item, to: $0) }
            )
        } customize: { params in
            params.centerPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDimLight)
        }
    }
}

// MARK: - Sections

private extension PlaylistFavoriteView {
    @ViewBuilder
    var content: some View {
        switch viewModel.tab {
        case .playlist:
            if viewModel.favoritePlaylists.isEmpty { emptyState } else { playlistList }
        case .channel:
            if viewModel.favoriteChannels.isEmpty { emptyState } else { channelGrid }
        }
    }

    var playlistList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.Spacing.sm) {
                ForEach(viewModel.favoritePlaylists, id: \.id) { playlist in
                    PlaylistCard(
                        playlist: playlist,
                        isFavorite: true,
                        onTap: { viewModel.open(playlist) },
                        onFavorite: { viewModel.removeFavorite(playlist) },
                        onDelete: { viewModel.askDelete(playlist) }
                    )
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.top, Layout.Spacing.m)
            .padding(.bottom, Layout.Spacing.s)
        }
    }

    var channelGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: PlaylistGrid.columns, spacing: Layout.Spacing.sm) {
                ForEach(viewModel.favoriteChannels) { item in
                    ChannelPosterCard(
                        channel: item.channel,
                        isFavorite: true,
                        onTap: { viewModel.open(item) },
                        onFavorite: { viewModel.removeFavorite(item) },
                        onRename: { viewModel.askRename(item) },
                        onShare: { viewModel.share(item) },
                        onDelete: { viewModel.askDelete(item) }
                    )
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.top, Layout.Spacing.m)
            .padding(.bottom, Layout.Spacing.s)
        }
    }

    var emptyState: some View {
        VStack(spacing: Layout.Spacing.s) {
            Text(viewModel.emptyTitle)
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
            Text(viewModel.emptySubtitle)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text2)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Layout.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
