//
//  PlaylistView.swift
//  I340_IPTV
//

import SwiftUI

/// Playlist tab: header, source chips, the imported playlists (or an empty state) and a native ad.
struct PlaylistView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, Layout.Spacing.m)

                optionChips
                    .padding(.top, 6)

                content
                    .padding(.top, 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                    MediumNativeAdView(frame: .zero)
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
        .actionMenu(
            activeID: viewModel.coordinator.actionMenuID,
            items: menuItems,
            onDismiss: viewModel.closeMenu
        )
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            alertContent(for: item)
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
        .popup(item: $viewModel.coordinator.rename) { playlist in
            RenameSheetView(
                title: viewModel.localized("playlist_rename_title", fallback: "Rename"),
                placeholder: viewModel.localized("playlist_rename_placeholder", fallback: "Playlist name"),
                continueTitle: viewModel.localized("playlist_rename_continue", fallback: "Continue"),
                emptyNameMessage: viewModel.localized("playlist_rename_empty_error", fallback: "The name cannot be left blank."),
                currentName: playlist.name,
                onClose: { viewModel.coordinator.rename = nil },
                onContinue: { viewModel.rename(playlist, to: $0) }
            )
        } customize: { params in
            params.bottomPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDim)
        }
    }

    private var menuItems: [ActionMenuItem] {
        guard let id = viewModel.coordinator.actionMenuID,
              let playlist = viewModel.playlists.first(where: { $0.id == id }) else { return [] }
        return viewModel.menuItems(for: playlist)
    }
}

// MARK: - Sections

private extension PlaylistView {
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

    var optionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.Spacing.s) {
                ForEach(viewModel.options, id: \.self) { option in
                    OptionChip(
                        option: option,
                        title: viewModel.title(for: option),
                        isSelected: option == viewModel.selectedOption
                    ) {
                        viewModel.select(option)
                    }
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
        }
        .frame(height: 44)
    }

    @ViewBuilder
    var content: some View {
        if viewModel.filteredPlaylists.isEmpty {
            emptyState
        } else {
            playlistList
        }
    }

    var playlistList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.Spacing.m) {
                ForEach(viewModel.filteredPlaylists) { playlist in
                    PlaylistItemRow(
                        playlist: playlist,
                        subtitle: viewModel.subtitle(for: playlist),
                        onTap: { viewModel.open(playlist) },
                        onMore: { viewModel.showMenu(for: playlist) }
                    )
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.bottom, Layout.Spacing.s)
        }
    }

    var emptyState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Asset.Icon.imgPlaylistEmpty.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 171, height: 165)
                    .padding(.top, 44)

                Text(viewModel.emptyTitle)
                    .font(FontFamily.Poppins.medium.font(size: 20))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, Layout.Spacing.l)

                Text(viewModel.emptySubtitle)
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(Asset.Color.textTertiary.color)
                    .multilineTextAlignment(.center)
                    .padding(.top, Layout.Spacing.s)

                Asset.Icon.imgPlaylistArrow.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 172, height: 173)
                    .offset(x: 52)
                    .padding(.top, Layout.Spacing.m)
            }
            .padding(.horizontal, Layout.Spacing.sm)
            .frame(maxWidth: .infinity)
        }
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
            ConfirmDialogView(
                title: viewModel.localized("playlist_delete_confirm_title", fallback: "Delete?"),
                message: viewModel.localized("playlist_delete_confirm_message", fallback: "Are you sure you want to delete this item?"),
                noTitle: viewModel.localized("playlist_delete_no", fallback: "No"),
                yesTitle: viewModel.localized("playlist_delete_yes", fallback: "Yes"),
                onNo: viewModel.dismissAlert,
                onYes: { viewModel.delete(playlist) }
            )
        }
    }
}

// MARK: - Chip

private struct OptionChip: View {
    let option: PlaylistOption
    let title: String
    let isSelected: Bool
    let action: () -> Void

    private var icon: ImageAsset {
        switch option {
        case .playlistURL: Asset.Icon.icMainChipLink
        case .file: Asset.Icon.icMainChipFile
        case .stream: Asset.Icon.icMainChipStream
        case .favorite: Asset.Icon.icMainChipFavorite
        }
    }

    var body: some View {
        let foreground = isSelected ? Color.black.opacity(0.8) : Color.white

        Button(action: action) {
            HStack(spacing: Layout.Spacing.xs) {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(foreground)
                    .frame(width: 16, height: 16)

                Text(title)
                    .font(isSelected ? FontFamily.Poppins.medium.font(size: 14) : FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, Layout.Spacing.m)
            .frame(minWidth: option.minimumWidth, minHeight: 44)
            .background(isSelected ? Color.white : Asset.Color.fieldBackground.color)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}
