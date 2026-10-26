//
//  XtreamFavoriteViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension XtreamFavoriteView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var favorites: [IPTVChannel] = []
        @Published var keyword = ""
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()

        let playlist: IPTVPlaylist?

        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void
        private var reloadToken = UUID()

        init(
            playlist: IPTVPlaylist?,
            onBack: @escaping () -> Void,
            favoriteStore: IPTVFavoriteChannelStore = .shared
        ) {
            self.playlist = playlist
            self.onBack = onBack
            self.favoriteStore = favoriteStore

            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        // MARK: - Derived state

        var screenTitle: String { "playlist_favorite_title".localized }

        var searchPlaceholder: String {
            String(format: "playlist_favorite_count_format".localized, favorites.count)
        }

        var avatarName: String {
            playlist.map { XtreamProfilePayload.decode(from: $0.url).avatarName } ?? "avatar_xtream_2"
        }

        var filteredFavorites: [IPTVChannel] {
            let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !text.isEmpty else { return favorites }
            return favorites.filter { channel in
                channel.title.lowercased().contains(text)
                    || channel.groupTitle.lowercased().contains(text)
                    || channel.url.lowercased().contains(text)
            }
        }

        var emptyText: String {
            favorites.isEmpty
                ? "playlist_no_favorite_channels".localized
                : "playlist_favorite_try_another_keyword".localized
        }

        // MARK: - Lifecycle & header

        func onAppear() {
            reload()
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

        // MARK: - Actions

        func didTapClearAll() {
            guard playlist != nil else { return }
            coordinator.alert = .clearAll
        }

        func confirmClearAll() {
            coordinator.alert = nil
            guard let playlist else { return }
            favoriteStore.removeAll(in: playlist.id)
            reloadToken = UUID()
            favorites = []
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        func remove(_ channel: IPTVChannel) {
            guard let playlist else { return }
            favoriteStore.remove(channel, in: playlist.id)
            let key = IPTVFavoriteChannelStore.favoriteKey(for: channel)
            favorites.removeAll { IPTVFavoriteChannelStore.favoriteKey(for: $0) == key }
        }

        func open(_ channel: IPTVChannel) {
            AppNavigator.push(.xtreamDetail(channel: channel, related: ChannelList(filteredFavorites), playlistID: playlist?.id))
        }

        // MARK: - Private

        private func reload() {
            guard let playlist else {
                favorites = []
                return
            }
            let token = UUID()
            reloadToken = token
            let channels = playlist.channels
            let playlistID = playlist.id

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let result = favoriteStore.favoriteChannels(from: channels, in: playlistID)
                DispatchQueue.main.async {
                    guard self.reloadToken == token else { return }
                    self.favorites = result
                }
            }
        }
    }
}
