//
//  XtreamContentViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

/// One titled row of channels (a group of the playlist).
struct XtreamSection: Identifiable {
    let title: String
    let channels: [IPTVChannel]

    var id: String { title }
}

extension XtreamContentView {
    typealias Tab = MediaTabs.Tab

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var profileName: String
        @Published private(set) var avatarName: String
        /// nil while the profile's channels are still being read from the database.
        @Published private(set) var playlist: IPTVPlaylist?
        @Published private(set) var selectedTab: Tab = .movies
        @Published private(set) var isSearching = false
        @Published var keyword = ""
        @Published private(set) var sections: [XtreamSection] = []
        @Published private(set) var featured: [IPTVChannel] = []
        @Published private(set) var isBuilding = false
        @Published private(set) var favoriteKeys = Set<String>()
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()

        private let profileID: String
        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void
        private var sectionCache: [Tab: [XtreamSection]] = [:]
        private var buildToken = UUID()
        private var cancellables = Set<AnyCancellable>()

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

            $keyword
                .dropFirst()
                .removeDuplicates()
                .sink { [weak self] _ in self?.rebuild() }
                .store(in: &cancellables)
        }

        // MARK: - Texts

        var searchPlaceholder: String { "playlist_search_channel".localized(fallback: "Search Channel") }

        /// What to show instead of the sections, or nil when there is something to list.
        var placeholderText: String? {
            if playlist == nil { return "xtream_content_loading".localized }
            if isBuilding {
                return String(format: "xtream_content_loading_tab_format".localized(fallback: "Loading %@..."), selectedTab.titleKey.localized)
            }
            if sections.isEmpty {
                return isSearching
                    ? "playlist_no_suitable_channels".localized(fallback: "No suitable channels found.")
                    : "xtream_content_empty".localized
            }
            return nil
        }

        var showsFeatured: Bool { selectedTab == .series && !isSearching && !featured.isEmpty }

        func isFavorite(_ channel: IPTVChannel) -> Bool {
            favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: channel))
        }

        // MARK: - Loading

        func update(with playlist: IPTVPlaylist) {
            self.playlist = playlist
            profileName = playlist.name
            avatarName = XtreamProfilePayload.decode(from: playlist.url).avatarName
            favoriteKeys = favoriteStore.favoriteKeySet(in: playlist.id)
            sectionCache.removeAll()
            exitSearch()
            rebuild()
        }

        func refreshFavorites() {
            guard let playlist else { return }
            favoriteKeys = favoriteStore.favoriteKeySet(in: playlist.id)
        }

        // MARK: - Actions

        func didTapBack() {
            if isSearching {
                exitSearch()
                rebuild()
                return
            }
            InterstitialGuard.perform(onBack)
        }

        func didTapSearch() {
            if isSearching {
                exitSearch()
                rebuild()
            } else if playlist != nil {
                isSearching = true
                rebuild()
            }
        }

        func didTapFavorites() {
            AppNavigator.push(.xtreamFavorites(playlist: playlist))
        }

        func select(_ tab: Tab) {
            selectedTab = tab
            rebuild()
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

        private func exitSearch() {
            isSearching = false
            if !keyword.isEmpty { keyword = "" }
        }

        private func rebuild() {
            guard let playlist else { return }

            let tab = selectedTab
            let searchKeyword = isSearching
                ? keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                : ""

            if searchKeyword.isEmpty, let cached = sectionCache[tab] {
                buildToken = UUID()
                apply(cached, tab: tab, isSearch: isSearching)
                return
            }

            isBuilding = true
            let token = UUID()
            buildToken = token
            let channels = playlist.channels
            let defaultTitle = Self.defaultSectionTitle(for: tab)

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let built = Self.makeSections(from: channels, tab: tab, defaultTitle: defaultTitle)
                let result = searchKeyword.isEmpty
                    ? built
                    : Self.filter(built, keyword: searchKeyword)

                DispatchQueue.main.async {
                    guard let self, self.buildToken == token else { return }
                    if searchKeyword.isEmpty { self.sectionCache[tab] = result }
                    self.apply(result, tab: tab, isSearch: self.isSearching)
                }
            }
        }

        private func apply(_ result: [XtreamSection], tab: Tab, isSearch: Bool) {
            sections = result
            featured = tab == .series && !isSearch ? Array(result.flatMap(\.channels).prefix(8)) : []
            isBuilding = false
        }

        private static func makeSections(from channels: [IPTVChannel], tab: Tab, defaultTitle: String) -> [XtreamSection] {
            let marker: String
            switch tab {
            case .movies: marker = "-vod-"
            case .series: marker = "-series-"
            case .liveTV: marker = "-live-"
            }

            let grouped = Dictionary(grouping: channels.filter { $0.id.contains(marker) }) { channel -> String in
                let name = channel.groupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                return name.isEmpty ? defaultTitle : name
            }

            return grouped
                .map { XtreamSection(title: $0.key, channels: $0.value) }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }

        private static func filter(_ sections: [XtreamSection], keyword: String) -> [XtreamSection] {
            sections.compactMap { section in
                let matches = section.channels.filter { channel in
                    channel.title.lowercased().contains(keyword)
                        || channel.groupTitle.lowercased().contains(keyword)
                        || channel.url.lowercased().contains(keyword)
                }
                return matches.isEmpty ? nil : XtreamSection(title: section.title, channels: matches)
            }
        }

        private static func defaultSectionTitle(for tab: Tab) -> String {
            switch tab {
            case .movies: "xtream_movies_library".localized
            case .series: "xtream_series_library".localized
            case .liveTV: "main_xtream_live_tv".localized
            }
        }
    }
}
