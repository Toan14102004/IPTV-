//
//  PlaylistView.swift
//  I340_IPTV
//

import SwiftUI

struct PlaylistView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            Color.background1.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(
                    title: viewModel.screenTitle,
                    onFavorite: viewModel.didTapFavorites,
                    onHelp: viewModel.didTapHelp,
                    onPremium: viewModel.premiumAction
                )

                if viewModel.hasPlaylists {
                    library
                } else {
                    emptyState
                }
            }

            if viewModel.isLoading {
                LoadingDialogView(
                    title: viewModel.localized("playlist_loading_title", fallback: "Loading..."),
                    message: viewModel.localized("playlist_loading_message", fallback: "Hang tight, it'll be worth the wait"),
                    closeTitle: viewModel.localized("playlist_loading_close", fallback: "Close"),
                    onClose: viewModel.didTapCloseLoading
                )
                .transition(.opacity)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("Playlist")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            alertContent(for: item)
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }

    private var nativeAd: some View {
        NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
            MediumNativeAdView(frame: .zero)
        }
    }
}

// MARK: - Empty state

private extension PlaylistView {
    var emptyState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                nativeAd

                VStack(spacing: Layout.Spacing.l) {
                    Asset.Image.imgPlaylistEmptyTitle.image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 325)
                        .padding(.horizontal, Layout.Spacing.l)

                    VStack(spacing: Layout.Spacing.xs) {
                        Text(viewModel.emptyTitle)
                            .font(Typography.subtitleLarge)
                            .foregroundStyle(Color.text1)
                        Text(viewModel.emptyMessage)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Color.text2)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Layout.Spacing.m)
                }
                .padding(.top, 66)

                Button(action: viewModel.didTapAddPlaylist) {
                    HStack(spacing: Layout.Spacing.s) {
                        Asset.Icon.icPlus.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text(viewModel.addPlaylistTitle)
                            .font(Typography.subtitleSmall)
                    }
                    .foregroundStyle(Color.text4)
                    .padding(Layout.Spacing.sm)
                    .frame(height: 48)
                    .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, Layout.Spacing.l)
            }
        }
    }
}

// MARK: - Library

private extension PlaylistView {
    var library: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                PlaylistSearchField(text: $viewModel.searchText)
                    .padding(.horizontal, Layout.Spacing.m)

                if viewModel.isSearchEmpty {
                    Text(viewModel.noResultTitle)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.text2)
                        .padding(.top, Layout.Spacing.xl)
                }

                nativeAd
                    .padding(.top, Layout.Spacing.m)

                VStack(spacing: Layout.Spacing.sm) {
                    PlaylistSectionHeader(section: .playlists, onSeeAll: { viewModel.didTapSeeAll(.playlists) })
                    if viewModel.homePlaylists.isEmpty {
                        AddPlaylistDashedCard(height: 90, action: viewModel.didTapAddPlaylist)
                    } else {
                        ForEach(viewModel.homePlaylists, id: \.id) { playlist in
                            card(for: playlist)
                        }
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.m)

                VStack(spacing: Layout.Spacing.sm) {
                    PlaylistSectionHeader(section: .videos, onSeeAll: { viewModel.didTapSeeAll(.videos) })
                    LazyVGrid(columns: PlaylistGrid.columns, spacing: Layout.Spacing.sm) {
                        ForEach(viewModel.homeVideos, id: \.id) { playlist in
                            VideoCard(
                                playlist: playlist,
                                isFavorite: viewModel.isFavorite(playlist),
                                onTap: { viewModel.open(playlist) },
                                onFavorite: { viewModel.toggleFavorite(playlist) },
                                onDelete: { viewModel.askDelete(playlist) }
                            )
                            .onAppear { viewModel.refreshDurationIfNeeded(playlist) }
                        }
                        if viewModel.homeVideos.isEmpty {
                            AddPlaylistDashedCard(action: viewModel.didTapAddFile)
                        }
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.m)
                .padding(.bottom, Layout.Spacing.l)
            }
            .padding(.top, Layout.Spacing.xs)
        }
        .scrollDismissesKeyboardIfAvailable()
    }

    func card(for playlist: IPTVPlaylist) -> some View {
        PlaylistCard(
            playlist: playlist,
            isFavorite: viewModel.isFavorite(playlist),
            onTap: { viewModel.open(playlist) },
            onFavorite: { viewModel.toggleFavorite(playlist) },
            onDelete: { viewModel.askDelete(playlist) }
        )
    }
}

// MARK: - Alerts

private extension PlaylistView {
    @ViewBuilder
    func alertContent(for alert: Coordinator.Alert) -> some View {
        switch alert {
        case .cancelImport:
            CustomAlertView(
                title: LocalizedStringKey(viewModel.localized("playlist_add_cancel_download_title", fallback: "Canceling a playlist download?")),
                description: LocalizedStringKey(viewModel.localized("playlist_add_cancel_download_message", fallback: "Your data will not be saved.")),
                cancelActionTitle: LocalizedStringKey(viewModel.localized("cancel", fallback: "Cancel")),
                cancelAction: viewModel.dismissAlert,
                primaryActionTitle: LocalizedStringKey(viewModel.localized("playlist_add_cancel_download_confirm", fallback: "Cancel download")),
                primaryActionTitleColor: .white,
                primaryAction: viewModel.confirmCancelImport
            )
        case .importTimeout:
            CustomAlertView(
                title: LocalizedStringKey(viewModel.localized("playlist_add_timeout_title", fallback: "Download timeout")),
                description: LocalizedStringKey(viewModel.localized("playlist_add_timeout_error", fallback: "The request timed out. Please try again.")),
                cancelActionTitle: LocalizedStringKey(viewModel.localized("cancel", fallback: "Cancel")),
                cancelAction: viewModel.dismissAlert,
                primaryActionTitle: LocalizedStringKey(viewModel.localized("playlist_add_retry", fallback: "Try again")),
                primaryActionTitleColor: .white,
                primaryAction: viewModel.retryImport
            )
        case let .deletePlaylist(playlist):
            PlaylistDeleteDialog(onNo: viewModel.dismissAlert, onYes: { viewModel.delete(playlist) })
        }
    }
}

struct PlaylistDeleteDialog: View {
    let onNo: () -> Void
    let onYes: () -> Void

    var body: some View {
        AppDialogView(
            title: "playlist_delete_confirm_title".localized(fallback: "Delete?"),
            message: "playlist_delete_confirm_message".localized(fallback: "Are you sure you want to delete this item?"),
            secondaryTitle: "playlist_delete_no".localized(fallback: "No"),
            primaryTitle: "playlist_delete_yes".localized(fallback: "Yes"),
            onSecondary: onNo,
            onPrimary: onYes
        )
    }
}
