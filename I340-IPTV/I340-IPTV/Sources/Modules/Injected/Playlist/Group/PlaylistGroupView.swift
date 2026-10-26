//
//  PlaylistGroupView.swift
//  I340_IPTV
//

import SwiftUI

struct PlaylistGroupView: View {
    @StateObject private var viewModel: ViewModel

    init(playlist: IPTVPlaylist, channel: IPTVChannel, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(playlist: playlist, channel: channel, onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: viewModel.title,
                    onBack: viewModel.didTapBack,
                    onPremium: viewModel.premiumAction
                )

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: PlaylistGrid.columns, spacing: Layout.Spacing.sm) {
                        ForEach(viewModel.channels) { channel in
                            ChannelPosterCard(
                                channel: channel,
                                isFavorite: viewModel.isFavorite(channel),
                                onTap: { viewModel.open(channel) },
                                onFavorite: { viewModel.toggleFavorite(channel) }
                            )
                        }
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                    .padding(.top, Layout.Spacing.xs)
                    .padding(.bottom, Layout.Spacing.s)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.isSubscribed {
                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("PlaylistGroup")
    }
}

/// Poster card of a channel (Figma "Card"): artwork with a gradient, title and group at the
/// bottom, a heart badge at the top right and a "more" button.
struct ChannelPosterCard: View {
    let channel: IPTVChannel
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    /// When set, the "more" menu offers these instead of only the favorite toggle.
    var onRename: (() -> Void)?
    var onShare: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        // The artwork stays a background so its fill size never widens the card.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: PlaylistGrid.cardHeight)
            .background(
                RemoteImageView(urlString: channel.imageURL, placeholder: Asset.Image.imgPlaylistItem, contentMode: .fill)
            )
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.45),
                        .init(color: .black.opacity(0.8), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .bottom) { info }
            .overlay(alignment: .topTrailing) { heart }
            .background(Color.text1)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
            .shadow(.card)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture(perform: onTap)
    }

    private var heart: some View {
        Button(action: onFavorite) {
            Group {
                if isFavorite {
                    Asset.Icon.icPlaylistFavoriteFilled.image.resizable()
                } else {
                    Asset.Icon.icPlaylistFavorite.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text4)
                }
            }
            .frame(width: 20, height: 20)
            .frame(width: 32, height: 32)
            .background(Color.white.opacity(0.2), in: Circle())
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(Layout.Spacing.sm)
    }

    private var info: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                Text(channel.title.isEmpty ? channel.url : channel.title)
                    .font(Typography.bodyLarge)
                    .lineLimit(1)
                Text(channel.groupTitle.isEmpty ? "Movies" : channel.groupTitle)
                    .font(Typography.labelSmall)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                if let onRename, let onShare, let onDelete {
                    Button(action: onRename) { Text("playlist_action_rename".localized(fallback: "Rename")) }
                    Button(action: onShare) { Text("playlist_action_share".localized(fallback: "Share")) }
                    Button(role: .destructive, action: onDelete) { Text("playlist_action_delete".localized(fallback: "Delete")) }
                } else {
                    Button(action: onFavorite) {
                        Text(isFavorite
                             ? "video_menu_favorite_remove".localized(fallback: "Remove from Favorites")
                             : "video_menu_favorite_add".localized(fallback: "Add to Favorites"))
                    }
                }
            } label: {
                Asset.Icon.icMoreVertical.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 32, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .foregroundStyle(Color.text4)
        .padding(.leading, Layout.Spacing.sm)
        .padding(.trailing, Layout.Spacing.xs)
        .padding(.bottom, Layout.Spacing.sm)
    }
}
