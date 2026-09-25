//
//  PlaylistChannelView.swift
//  I340_IPTV
//

import SwiftUI

/// Channels of one playlist with search, favorites, rename and delete.
struct PlaylistChannelView: View {
    @StateObject private var viewModel: ViewModel
    @FocusState private var isSearchFocused: Bool

    init(playlist: IPTVPlaylist, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(playlist: playlist, onBack: onBack))
    }

    var body: some View {
        ZStack {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: Layout.Spacing.sm) {
                    BackButton(action: viewModel.didTapBack)
                        .frame(width: 24, height: 24)
                    SearchBar(
                        text: $viewModel.keyword,
                        placeholder: viewModel.searchPlaceholder,
                        isFocused: $isSearchFocused
                    )
                }
                .padding(.horizontal, Layout.Spacing.m)

                content
                    .padding(.top, Layout.Spacing.m)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.isSubscribed {
                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("PlaylistChannel")
        .actionMenu(activeID: viewModel.coordinator.actionMenuID, items: menuItems, onDismiss: viewModel.closeMenu)
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case let .deleteChannel(channel):
                ConfirmDialogView(
                    title: "playlist_delete_confirm_title".localized(fallback: "Delete?"),
                    message: "playlist_delete_confirm_message".localized(fallback: "Are you sure you want to delete this item?"),
                    noTitle: "playlist_delete_no".localized(fallback: "No"),
                    yesTitle: "playlist_delete_yes".localized(fallback: "Yes"),
                    onNo: viewModel.dismissAlert,
                    onYes: { viewModel.delete(channel) }
                )
            }
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
        .popup(item: $viewModel.coordinator.rename) { channel in
            RenameSheetView(
                title: "playlist_rename_title".localized(fallback: "Rename"),
                placeholder: "playlist_rename_placeholder".localized(fallback: "Playlist name"),
                continueTitle: "playlist_rename_continue".localized(fallback: "Continue"),
                emptyNameMessage: "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank."),
                currentName: channel.title.isEmpty ? channel.url : channel.title,
                onClose: { viewModel.coordinator.rename = nil },
                onContinue: { viewModel.rename(channel, to: $0) }
            )
        } customize: { params in
            params.bottomPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDim)
        }
    }

    private var menuItems: [ActionMenuItem] {
        guard let id = viewModel.coordinator.actionMenuID,
              let channel = viewModel.playlist.channels.first(where: { $0.id == id }) else { return [] }
        return viewModel.menuItems(for: channel)
    }

    @ViewBuilder
    private var content: some View {
        let channels = viewModel.filteredChannels
        if channels.isEmpty {
            Text(viewModel.emptyMessage)
                .font(FontFamily.Poppins.medium.font(size: 16))
                .foregroundColor(Asset.Color.textGray.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Layout.Spacing.m) {
                    ForEach(channels) { channel in
                        ChannelRow(
                            channel: channel,
                            isFavorite: viewModel.isFavorite(channel),
                            onTap: { viewModel.open(channel) },
                            onFavorite: { viewModel.toggleFavorite(channel) },
                            onMore: { viewModel.showMenu(for: channel) }
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
