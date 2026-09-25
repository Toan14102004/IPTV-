//
//  PlaylistFavoriteViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension PlaylistFavoriteView {
    /// A favorite channel together with the playlist it belongs to.
    struct Item: Identifiable {
        let playlist: IPTVPlaylist
        let channel: IPTVChannel

        var id: String { playlist.id + "|" + channel.id }
    }

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var playlists: [IPTVPlaylist] = []
        @Published private(set) var favoriteKeys: Set<String>
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var keyword = ""
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

        var screenTitle: String { "playlist_favorite_title".localized(fallback: "Favourite") }

        var items: [Item] {
            playlists.flatMap { playlist in
                playlist.channels
                    .filter { favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: $0)) }
                    .map { Item(playlist: playlist, channel: $0) }
            }
        }

        var filteredItems: [Item] {
            let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !text.isEmpty else { return items }
            return items.filter {
                $0.channel.title.lowercased().contains(text)
                    || $0.channel.groupTitle.lowercased().contains(text)
                    || $0.channel.url.lowercased().contains(text)
                    || $0.playlist.name.lowercased().contains(text)
            }
        }

        var searchPlaceholder: String {
            String(
                format: "playlist_favorite_count_format".localized(fallback: "Favourite (%d)"),
                items.count
            )
        }

        var emptyTitle: String {
            if items.isEmpty {
                return "playlist_no_favorite_channels".localized(fallback: "No favorite channels yet")
            }
            return "playlist_no_suitable_channels".localized(fallback: "No suitable channels found.")
        }

        var emptySubtitle: String {
            if items.isEmpty {
                return "playlist_tap_heart_channel".localized(fallback: "Tap the heart on a channel to save it here.")
            }
            return "playlist_favorite_try_another_keyword".localized(fallback: "Try another keyword.")
        }

        // MARK: - Actions

        func onAppear() {
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    playlists = try await playlistManager.getPlaylists()
                    favoriteKeys = favoriteStore.favoriteKeys
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func didTapPremium() {
            AppNavigator.presentPaywall()
        }

        func didTapSettings() {
            InterstitialGuard.perform { AppNavigator.push(.settings) }
        }

        func didTapHelp() {
            InterstitialGuard.perform { AppNavigator.present(.guide) }
        }

        func didTapClearAll() {
            guard !items.isEmpty else { return }
            coordinator.alert = .clearAll
        }

        func open(_ item: Item) {
            AppNavigator.push(.playlistPlayer(playlist: item.playlist, channel: item.channel))
        }

        func removeFavorite(_ channel: IPTVChannel) {
            favoriteStore.remove(channel)
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func showMenu(for item: Item) {
            coordinator.actionMenuID = item.id
        }

        func closeMenu() {
            coordinator.actionMenuID = nil
        }

        func menuItems(for item: Item) -> [ActionMenuItem] {
            [
                ActionMenuItem(
                    title: "playlist_action_delete".localized(fallback: "Delete"),
                    systemImage: "trash"
                ) { [weak self] in self?.coordinator.alert = .remove(item.channel) }
            ]
        }

        func confirmClearAll() {
            coordinator.alert = nil
            favoriteStore.removeAll()
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func confirmRemove(_ channel: IPTVChannel) {
            coordinator.alert = nil
            removeFavorite(channel)
        }

        func dismissAlert() {
            coordinator.alert = nil
        }
    }
}
