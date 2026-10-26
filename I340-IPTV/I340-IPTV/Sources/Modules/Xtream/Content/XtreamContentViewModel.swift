//
//  XtreamContentViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

struct XtreamSection: Identifiable {
    let title: String
    let channels: [IPTVChannel]

    var id: String { title }
}

extension XtreamContentView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var profileName: String
        @Published private(set) var avatarName: String
        /// nil while the profile's channels are still being read from the database.
        @Published private(set) var playlist: IPTVPlaylist?
        @Published private(set) var sections: [XtreamSection] = []
        @Published private(set) var isBuilding = false
        @Published private(set) var favoriteKeys = Set<String>()
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()

        private let profileID: String
        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void
        private var buildToken = UUID()

        init(
            profileName: String,
            avatarName: String,
            profileID: String,
            favoriteStore: IPTVFavoriteChannelStore = .shared,
            onBack: @escaping () -> Void
        ) {
            self.profileName = profileName
            self.avatarName = avatarName
            self.profileID = profileID
            self.favoriteStore = favoriteStore
            self.onBack = onBack
        }

        // MARK: - Texts

        /// What to show instead of the sections, or nil when there is something to list.
        var placeholderText: String? {
            if playlist == nil || isBuilding { return "xtream_content_loading".localized }
            if sections.isEmpty { return "xtream_content_empty".localized }
            return nil
        }

        var premiumAction: (() -> Void)? {
            isSubscribed ? nil : { AppNavigator.presentPaywall() }
        }

        func isFavorite(_ channel: IPTVChannel) -> Bool {
            favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: channel))
        }

        // MARK: - Loading

        func update(with playlist: IPTVPlaylist) {
            self.playlist = playlist
            profileName = playlist.name
            avatarName = XtreamProfilePayload.decode(from: playlist.url).avatarName
            favoriteKeys = favoriteStore.favoriteKeySet(in: playlist.id)
            rebuild()
        }

        func refreshFavorites() {
            guard let playlist else { return }
            favoriteKeys = favoriteStore.favoriteKeySet(in: playlist.id)
        }

        // MARK: - Actions

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func didTapFavorites() {
            AppNavigator.push(.xtreamFavorites(playlist: playlist))
        }

        func open(_ channel: IPTVChannel, in channels: [IPTVChannel]) {
            AppNavigator.push(.xtreamDetail(channel: channel, related: ChannelList(channels), playlistID: profileID))
        }

        func toggleFavorite(_ channel: IPTVChannel) {
            guard let playlist else { return }
            let isFavorite = favoriteStore.toggle(channel, in: playlist.id)
            let key = IPTVFavoriteChannelStore.favoriteKey(for: channel)
            if isFavorite {
                favoriteKeys.insert(key)
            } else {
                favoriteKeys.remove(key)
            }
        }

        // MARK: - Sections

        /// Groups every channel (live, movies and series) by its category.
        private func rebuild() {
            guard let playlist else { return }

            isBuilding = true
            let token = UUID()
            buildToken = token
            let channels = playlist.channels
            let defaultTitle = "xtream_movies_library".localized

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let grouped = Dictionary(grouping: channels) { channel -> String in
                    let name = channel.groupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    return name.isEmpty ? defaultTitle : name
                }
                let built = grouped
                    .map { XtreamSection(title: $0.key, channels: $0.value) }
                    .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

                DispatchQueue.main.async {
                    guard let self, self.buildToken == token else { return }
                    self.sections = built
                    self.isBuilding = false
                }
            }
        }
    }
}
