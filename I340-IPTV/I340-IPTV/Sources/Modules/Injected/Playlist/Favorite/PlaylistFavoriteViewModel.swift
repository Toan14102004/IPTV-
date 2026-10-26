//
//  PlaylistFavoriteViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension PlaylistFavoriteView {
    enum Tab: Int, CaseIterable {
        case playlist
        case channel
    }

    struct Item: Identifiable, Hashable {
        let playlist: IPTVPlaylist
        let channel: IPTVChannel

        var id: String { playlist.id + "|" + channel.id }

        static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published var tab = Tab.playlist
        @Published private(set) var playlists: [IPTVPlaylist] = []
        @Published private(set) var favoriteKeys: Set<String>
        @Published private(set) var favoritePlaylistIDs = Set(UserDefaultManager.shared().favoritePlaylistIDs)
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        @Injected private var playlistManager: IPTVPlaylistManager
        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void

        init(
            onBack: @escaping () -> Void,
            favoriteStore: IPTVFavoriteChannelStore = .shared
        ) {
            self.onBack = onBack
            self.favoriteStore = favoriteStore
            favoriteKeys = favoriteStore.favoriteKeys

            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        // MARK: - Derived state

        var screenTitle: String { "playlist_favorite_title".localized(fallback: "Favorite") }

        var tabTitles: [String] {
            [
                "main_playlist".localized(fallback: "Playlist"),
                "playlist_favorite_tab_channel".localized(fallback: "Channel")
            ]
        }

        /// Playlists and videos with a heart, in the order of the library.
        var favoritePlaylists: [IPTVPlaylist] {
            playlists.filter { favoritePlaylistIDs.contains($0.id) && $0.source != .xtream }
        }

        var favoriteChannels: [Item] {
            playlists.flatMap { playlist in
                playlist.channels
                    .filter { favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: $0)) }
                    .map { Item(playlist: playlist, channel: $0) }
            }
        }

        var premiumAction: (() -> Void)? {
            isSubscribed ? nil : { AppNavigator.presentPaywall() }
        }

        var emptyTitle: String {
            switch tab {
            case .playlist: "playlist_no_favorite_playlists".localized(fallback: "No favorite playlists yet")
            case .channel: "playlist_no_favorite_channels".localized(fallback: "No favorite channels yet")
            }
        }

        var emptySubtitle: String {
            switch tab {
            case .playlist: "playlist_tap_heart_playlist".localized(fallback: "Tap the heart on a playlist to save it here.")
            case .channel: "playlist_tap_heart_channel".localized(fallback: "Tap the heart on a channel to save it here.")
            }
        }

        // MARK: - Lifecycle

        func onAppear() {
            Task { @MainActor [weak self] in await self?.reload() }
        }

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func select(_ index: Int) {
            tab = Tab(rawValue: index) ?? .playlist
        }

        // MARK: - Playlists

        func open(_ playlist: IPTVPlaylist) {
            AppNavigator.push(playlist.opensPlayerDirectly ? .playVideo(playlist: playlist) : .playlistChannels(playlist: playlist))
        }

        func removeFavorite(_ playlist: IPTVPlaylist) {
            favoritePlaylistIDs = PlaylistFavorites.remove(playlist.id)
        }

        func askDelete(_ playlist: IPTVPlaylist) {
            coordinator.alert = .deletePlaylist(playlist)
        }

        func delete(_ playlist: IPTVPlaylist) {
            coordinator.alert = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await playlistManager.deletePlaylist(id: playlist.id)
                    favoritePlaylistIDs = PlaylistFavorites.remove(playlist.id)
                    await reload()
                    toast = "playlist_delete_success".localized(fallback: "Playlist deleted successfully.")
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        // MARK: - Channels

        func open(_ item: Item) {
            let single = IPTVPlaylist(
                id: item.channel.id,
                name: item.channel.title.isEmpty ? item.playlist.name : item.channel.title,
                url: item.channel.url,
                source: item.playlist.source,
                channels: [item.channel]
            )
            InterstitialGuard.perform { AppNavigator.push(.playVideo(playlist: single)) }
        }

        func removeFavorite(_ item: Item) {
            favoriteStore.remove(item.channel)
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func askRename(_ item: Item) {
            coordinator.rename = item
        }

        func askDelete(_ item: Item) {
            coordinator.alert = .deleteChannel(item)
        }

        /// Shares the title and the app link, never the stream address: it can carry credentials.
        func share(_ item: Item) {
            let title = item.channel.title.isEmpty ? item.playlist.name : item.channel.title
            UIApplication.shared.share(items: [title, "https://apps.apple.com/app/id\(Configs.InfoApp.appId)"])
        }

        func rename(_ item: Item, to name: String) {
            coordinator.rename = nil
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                toast = "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank.")
                return
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    _ = try await playlistManager.renameChannel(in: item.playlist, channel: item.channel, to: name)
                    await reload()
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        func delete(_ item: Item) {
            coordinator.alert = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    _ = try await playlistManager.deleteChannel(from: item.playlist, channel: item.channel)
                    favoriteStore.remove(item.channel)
                    await reload()
                    toast = "playlist_channel_delete_success".localized(fallback: "Channel deleted successfully.")
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        // MARK: - Private

        @MainActor
        private func reload() async {
            do {
                playlists = try await playlistManager.getPlaylists()
                favoriteKeys = favoriteStore.favoriteKeys
                favoritePlaylistIDs = Set(UserDefaultManager.shared().favoritePlaylistIDs)
            } catch {
                toast = IPTVPlaylistError.message(for: error)
            }
        }
    }
}
