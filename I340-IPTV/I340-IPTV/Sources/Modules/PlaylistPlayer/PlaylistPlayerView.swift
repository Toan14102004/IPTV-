//
//  PlaylistPlayerView.swift
//  I340_IPTV
//

import SwiftUI

/// Video player for a playlist with the list of its channels underneath.
struct PlaylistPlayerView: View {
    @StateObject private var viewModel: ViewModel

    init(playlist: IPTVPlaylist, channel: IPTVChannel, onBack: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: ViewModel(playlist: playlist, selectedChannel: channel, onBack: onBack)
        )
    }

    var body: some View {
        PlaylistPlayerContent(viewModel: viewModel, player: viewModel.player)
    }
}

private struct PlaylistPlayerContent: View {
    typealias ViewModel = PlaylistPlayerView.ViewModel

    @ObservedObject var viewModel: ViewModel
    /// Observed directly: changes of this nested object do not notify `viewModel`.
    @ObservedObject var player: PlayerController

    var body: some View {
        ZStack(alignment: .top) {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            VStack(spacing: 0) {
                playerArea

                if !player.isFullscreen {
                    channelBar
                        .padding(.horizontal, Layout.Spacing.m)
                        .padding(.top, Layout.Spacing.m)

                    channelList
                        .padding(.top, Layout.Spacing.m)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !viewModel.isSubscribed {
                        NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                            MediumNativeAdView(frame: .zero)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: player.isFullscreen ? .all : [])
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .trackScreen("PlaylistPlayer")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { _ in
            CustomAlertView(
                title: LocalizedStringKey("playlist_player_error_title".localized(fallback: "Unable to play channel")),
                description: LocalizedStringKey(
                    "playlist_player_error_message".localized(
                        fallback: "This channel cannot be played. Please try another channel."
                    )
                ),
                cancelActionTitle: nil,
                primaryActionTitle: LocalizedStringKey(
                    "playlist_player_choose_other".localized(fallback: "Choose another channel")
                ),
                primaryActionTitleColor: .white,
                primaryAction: viewModel.dismissAlert
            )
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }
}

// MARK: - Player

private extension PlaylistPlayerContent {
    var playerArea: some View {
        ZStack {
            Color.black

            PlayerSurfaceView(controller: player)

            if player.showsPreview {
                previewImage
            }

            PlayerControlsOverlay(
                controller: player,
                loadingText: viewModel.loadingText,
                networkLostText: viewModel.networkLostText,
                onBack: viewModel.didTapBack
            )
        }
        .frame(height: player.isFullscreen ? nil : UIScreen.main.bounds.height * 0.36)
        .frame(maxHeight: player.isFullscreen ? .infinity : nil)
        .clipped()
    }

    var previewImage: some View {
        Group {
            if let channel = viewModel.currentChannel, !channel.imageURL.isEmpty {
                RemoteImageView(
                    urlString: channel.imageURL,
                    placeholder: Asset.Icon.icChannelPlayerDefault,
                    contentMode: .fill
                )
            } else {
                Asset.Icon.icChannelPlayerDefault.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(Color.black)
        .allowsHitTesting(false)
    }
}

// MARK: - Channels

private extension PlaylistPlayerContent {
    /// The channel being played: logo, name, group and the "now playing" icon.
    var channelBar: some View {
        let channel = viewModel.currentChannel
        return HStack(spacing: Layout.Spacing.s) {
            RemoteImageView(
                urlString: channel?.imageURL ?? "",
                placeholder: Asset.Icon.icChannelPlayerDefault
            )
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: Layout.Spacing.xxs) {
                Text(displayTitle(channel))
                    .font(FontFamily.Poppins.medium.font(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(displayGroup(channel))
                    .font(FontFamily.Poppins.regular.font(size: 12))
                    .foregroundColor(Asset.Color.textGray.color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Asset.Icon.icChannelPlayerVoice.image
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, Layout.Spacing.sm)
        .frame(height: 70)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Asset.Color.dividerBlue.color).frame(height: 1)
        }
    }

    var channelList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.Spacing.m) {
                ForEach(Array(viewModel.channels.enumerated()), id: \.element.id) { index, channel in
                    PlayerChannelRow(
                        channel: channel,
                        title: displayTitle(channel),
                        group: displayGroup(channel),
                        isCurrent: index == viewModel.selectedIndex,
                        isFavorite: viewModel.isFavorite(channel),
                        onTap: { viewModel.select(at: index) },
                        onFavorite: { viewModel.toggleFavorite(channel) }
                    )
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.bottom, Layout.Spacing.s)
        }
    }

    func displayTitle(_ channel: IPTVChannel?) -> String {
        guard let channel else { return "" }
        return channel.title.isEmpty ? channel.url : channel.title
    }

    func displayGroup(_ channel: IPTVChannel?) -> String {
        guard let channel else { return "" }
        return channel.groupTitle.isEmpty ? "main_xtream_movies".localized : channel.groupTitle
    }
}

private struct PlayerChannelRow: View {
    let channel: IPTVChannel
    let title: String
    let group: String
    let isCurrent: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.s) {
            RemoteImageView(urlString: channel.imageURL, placeholder: Asset.Icon.icChannelPlayerDefault)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(FontFamily.Poppins.medium.font(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(group)
                    .font(FontFamily.Poppins.regular.font(size: 12))
                    .foregroundColor(Asset.Color.textGray.color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Layout.Spacing.s) {
                if isCurrent {
                    Asset.Icon.icChannelPlayerVoice.image
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }

                Button(action: onFavorite) {
                    (isFavorite ? Asset.Icon.icChannelPlayerHeartFilled : Asset.Icon.icChannelPlayerHeartOutline)
                        .image
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Layout.Spacing.sm)
        .frame(height: 84)
        .background(Asset.Color.cardBackground.color)
        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: Layout.CornerRadius.large).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        .onTapGesture(perform: onTap)
    }
}
