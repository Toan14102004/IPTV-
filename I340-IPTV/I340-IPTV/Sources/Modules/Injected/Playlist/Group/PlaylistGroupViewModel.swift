//
//  PlaylistGroupViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation

extension PlaylistGroupView {
    /// Poster grid shown after a channel of the playlist was tapped (Figma "Playlist").
    final class ViewModel: ObservableObject {
        @Published private(set) var favoriteKeys: Set<String>
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()

        let playlist: IPTVPlaylist
        let channel: IPTVChannel
        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void

        init(
            playlist: IPTVPlaylist,
            channel: IPTVChannel,
            onBack: @escaping () -> Void,
            favoriteStore: IPTVFavoriteChannelStore = .shared
        ) {
            self.playlist = playlist
            self.channel = channel
            self.onBack = onBack
            self.favoriteStore = favoriteStore
            favoriteKeys = favoriteStore.favoriteKeys

            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        var title: String { channel.title.isEmpty ? playlist.name : channel.title }
        var channels: [IPTVChannel] { playlist.channels }

        var premiumAction: (() -> Void)? {
            isSubscribed ? nil : { AppNavigator.presentPaywall() }
        }

        func onAppear() {
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func isFavorite(_ channel: IPTVChannel) -> Bool {
            favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: channel))
        }

        func toggleFavorite(_ channel: IPTVChannel) {
            favoriteStore.toggle(channel)
            favoriteKeys = favoriteStore.favoriteKeys
        }

        /// Plays the title on Play Video, which also offers Watch Together.
        ///
        /// Carries the whole grid's channels (not just the tapped one) so "Next Channel" on a
        /// playback-failure dialog has somewhere to go.
        func open(_ channel: IPTVChannel) {
            let siblings = playlist.channels.contains(where: { $0.id == channel.id }) ? playlist.channels : [channel]
            let item = IPTVPlaylist(
                id: channel.id,
                name: channel.title.isEmpty ? playlist.name : channel.title,
                url: channel.url,
                source: playlist.source,
                channels: siblings
            )
            InterstitialGuard.perform { AppNavigator.push(.playVideo(playlist: item)) }
        }
    }
}
