//
//  PlaylistChannelViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension PlaylistChannelView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var playlist: IPTVPlaylist
        @Published var keyword = ""
        @Published private(set) var favoriteKeys: Set<String>
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        @Injected private var playlistManager: IPTVPlaylistManager
        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void

        init(
            playlist: IPTVPlaylist,
            onBack: @escaping () -> Void,
            favoriteStore: IPTVFavoriteChannelStore = .shared
        ) {
            self.playlist = playlist
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

        var searchPlaceholder: String { "playlist_search_channel".localized(fallback: "Search Channel") }
        var emptyMessage: String { "playlist_no_suitable_channels".localized(fallback: "No suitable channels found.") }

        var premiumAction: (() -> Void)? {
            isSubscribed ? nil : { AppNavigator.presentPaywall() }
        }

        var channelCountText: String { playlist.channelCountText }

        var filteredChannels: [IPTVChannel] {
            let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return playlist.channels }
            return playlist.channels.filter { channel in
                let title = channel.title.isEmpty ? channel.url : channel.title
                return title.localizedCaseInsensitiveContains(text)
            }
        }

        func isFavorite(_ channel: IPTVChannel) -> Bool {
            favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: channel))
        }

        // MARK: - Actions

        /// The player may have changed favorites while it was on top of this screen.
        func onAppear() {
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func open(_ channel: IPTVChannel) {
            // A device file or single stream is one video, not a grouped playlist: play it directly.
            guard playlist.source != .file, playlist.source != .stream else {
                let item = IPTVPlaylist(
                    id: channel.id,
                    name: channel.title.isEmpty ? playlist.name : channel.title,
                    url: channel.url,
                    source: playlist.source,
                    channels: [channel]
                )
                InterstitialGuard.perform { AppNavigator.push(.playVideo(playlist: item)) }
                return
            }
            AppNavigator.push(.playlistGroup(playlist: playlist, channel: channel))
        }

        func toggleFavorite(_ channel: IPTVChannel) {
            favoriteStore.toggle(channel)
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func showMenu(for channel: IPTVChannel) {
            coordinator.actionMenuID = channel.id
        }

        func closeMenu() {
            coordinator.actionMenuID = nil
        }

        func menuItems(for channel: IPTVChannel) -> [ActionMenuItem] {
            [
                ActionMenuItem(
                    title: "playlist_action_rename".localized(fallback: "Rename"),
                    systemImage: "square.and.pencil"
                ) { [weak self] in self?.coordinator.rename = channel },
                ActionMenuItem(
                    title: "playlist_action_delete".localized(fallback: "Delete"),
                    systemImage: "trash"
                ) { [weak self] in self?.coordinator.alert = .deleteChannel(channel) }
            ]
        }

        func rename(_ channel: IPTVChannel, to name: String) {
            coordinator.rename = nil
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                toast = "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank.")
                return
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    playlist = try await playlistManager.renameChannel(in: playlist, channel: channel, to: name)
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        func delete(_ channel: IPTVChannel) {
            coordinator.alert = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    playlist = try await playlistManager.deleteChannel(from: playlist, channel: channel)
                    favoriteStore.remove(channel)
                    favoriteKeys = favoriteStore.favoriteKeys
                    toast = "playlist_channel_delete_success".localized(fallback: "Channel deleted successfully.")
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        func dismissAlert() {
            coordinator.alert = nil
        }
    }
}
