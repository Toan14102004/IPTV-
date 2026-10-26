//
//  PlaylistViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension PlaylistView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var playlists: [IPTVPlaylist] = []
        @Published private(set) var favoriteIDs = Set(UserDefaultManager.shared().favoritePlaylistIDs)
        @Published private(set) var isLoading = false
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var searchText = ""
        @Published var toast: String?

        var onRequestAdd: (() -> Void)?

        private let homeLimit = 3

        @Injected private var playlistManager: IPTVPlaylistManager

        private var importTask: Task<Void, Never>?
        private var retryImportAction: (() -> Void)?

        init() {
            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        // MARK: - Derived state

        var hasPlaylists: Bool {
            playlists.contains { PlaylistSection.playlists.contains($0) || PlaylistSection.videos.contains($0) }
        }

        var homePlaylists: [IPTVPlaylist] { Array(matching(.playlists).prefix(homeLimit)) }
        var homeVideos: [IPTVPlaylist] { Array(matching(.videos).prefix(homeLimit)) }

        var isSearchEmpty: Bool {
            !trimmedSearch.isEmpty && matching(.playlists).isEmpty && matching(.videos).isEmpty
        }

        func isFavorite(_ playlist: IPTVPlaylist) -> Bool {
            favoriteIDs.contains(playlist.id)
        }

        var screenTitle: String { localized("main_playlist", fallback: "Playlist") }
        var emptyTitle: String { localized("playlist_empty_title", fallback: "You don't have any playlists") }
        var emptyMessage: String {
            localized("playlist_empty_message", fallback: "Xtream Codes is the most popular and widely used platform for IPTV streaming.")
        }
        var addPlaylistTitle: String { localized("playlist_add_playlist", fallback: "Add Playlist") }
        var noResultTitle: String { localized("playlist_search_no_result", fallback: "No playlists found") }

        var premiumAction: (() -> Void)? {
            isSubscribed ? nil : { [weak self] in self?.didTapPremium() }
        }

        // MARK: - Lifecycle & header

        func onAppear() {
            favoriteIDs = Set(UserDefaultManager.shared().favoritePlaylistIDs)
            Task { @MainActor [weak self] in
                await self?.reloadPlaylists()
            }
        }

        func didTapPremium() {
            AppNavigator.presentPaywall()
        }

        func didTapFavorites() {
            InterstitialGuard.perform { AppNavigator.push(.playlistFavorites) }
        }

        func didTapHelp() {
            InterstitialGuard.perform { AppNavigator.present(.guide) }
        }

        // MARK: - Library

        func didTapAddPlaylist() {
            onRequestAdd?()
        }

        func didTapAddFile() {
            AppNavigator.push(.importPlaylist(tab: .file))
        }

        func didTapSeeAll(_ section: PlaylistSection) {
            InterstitialGuard.perform { AppNavigator.push(.playlistList(section: section)) }
        }

        func open(_ playlist: IPTVPlaylist) {
            AppNavigator.push(playlist.opensPlayerDirectly ? .playVideo(playlist: playlist) : .playlistChannels(playlist: playlist))
        }

        func toggleFavorite(_ playlist: IPTVPlaylist) {
            favoriteIDs = PlaylistFavorites.toggle(playlist.id)
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
                    favoriteIDs = PlaylistFavorites.remove(playlist.id)
                    await reloadPlaylists()
                    toast = localized("playlist_delete_success", fallback: "Playlist deleted successfully.")
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        // MARK: - Import

        func didTapCloseLoading() {
            coordinator.alert = .cancelImport
        }

        func confirmCancelImport() {
            coordinator.alert = nil
            importTask?.cancel()
            importTask = nil
            retryImportAction = nil
            setLoading(false)
        }

        func retryImport() {
            coordinator.alert = nil
            retryImportAction?()
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        // MARK: - Add flow (the sheets are shown by `ContentView`)

        /// Saves an Xtream profile typed in the add form; returns an error message, nil on success.
        func addXtreamProfile(_ profile: XtreamProfileItem) async -> String? {
            do {
                _ = try await playlistManager.saveXtreamProfile(
                    name: profile.name,
                    serverURL: profile.serverURL,
                    username: profile.profileID,
                    password: profile.password,
                    avatarName: profile.avatarName
                )
                await reloadPlaylists()
                return nil
            } catch {
                return IPTVPlaylistError.message(for: error)
            }
        }

        func handleAddSubmission(_ submission: PlaylistAddChannelSubmission) {
            let manager = playlistManager
            switch submission {
            case let .m3u(name, url):
                let playlistName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let playlistURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !playlistName.isEmpty, !playlistURL.isEmpty else {
                    toast = localized("playlist_add_name_url_empty_error", fallback: "Please enter playlist name and URL.")
                    return
                }
                runImport { try await manager.importRemotePlaylist(name: playlistName, url: playlistURL) }
            case let .file(name, fileURL):
                runImport { try await manager.importLocalFile(fileURL: fileURL, name: name) }
            case let .stream(name, url):
                runImport { try await manager.importSingleStream(name: name, url: url) }
            }
        }

        private func handleImported(_ playlist: IPTVPlaylist) {
            AnalyticsService.shared.log(.custom("import_playlist", [
                "source": playlist.source.rawValue,
                "channels": playlist.channels.count
            ]))
            toast = playlist.channels.isEmpty
                ? localized("playlist_add_empty_channels_warning", fallback: "The playlist contains no channels.")
                : localized("playlist_add_success", fallback: "Playlist imported successfully.")
            // A file or single stream lands in the VIDEOS section; links open their channels.
            if playlist.source != .file, playlist.source != .stream { open(playlist) }
            if !playlist.channels.isEmpty, playlist.source != .stream {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showRateForApp()
                }
            }
        }

        // MARK: - Private

        private var trimmedSearch: String {
            searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private func matching(_ section: PlaylistSection) -> [IPTVPlaylist] {
            let query = trimmedSearch
            return playlists.filter { playlist in
                section.contains(playlist)
                    && (query.isEmpty || playlist.name.localizedCaseInsensitiveContains(query))
            }
        }

        private func reloadPlaylists() async {
            do {
                playlists = try await playlistManager.getPlaylists()
            } catch {
                Logger.e("Loading playlists failed", error)
                toast = IPTVPlaylistError.message(for: error)
            }
        }

        private func setLoading(_ value: Bool) {
            withAnimation(.easeOut(duration: 0.2)) { isLoading = value }
        }

        /// Runs one import with the loading dialog; cancelling or retrying works on `work` as a whole.
        private func runImport(_ work: @escaping () async throws -> IPTVPlaylist) {
            guard !isLoading else { return }
            retryImportAction = { [weak self] in self?.runImport(work) }
            setLoading(true)

            importTask = Task { @MainActor [weak self] in
                do {
                    let playlist = try await work()
                    guard let self, !Task.isCancelled else { return }
                    finishImport(keepRetryAction: false)
                    await reloadPlaylists()
                    handleImported(playlist)
                } catch {
                    guard let self, !Task.isCancelled else { return }
                    handleImportFailure(error)
                }
            }
        }

        private func finishImport(keepRetryAction: Bool) {
            importTask = nil
            if !keepRetryAction {
                retryImportAction = nil
            }
            setLoading(false)
        }

        private func handleImportFailure(_ error: Error) {
            Logger.e("Import failed", error)
            if case IPTVPlaylistError.playlistRequestTimeout = error {
                finishImport(keepRetryAction: true)
                coordinator.alert = .importTimeout
            } else {
                finishImport(keepRetryAction: false)
                toast = IPTVPlaylistError.message(for: error)
            }
        }

        func localized(_ key: String, fallback: String) -> String {
            let value = key.localized
            return value == key || value.isEmpty ? fallback : value
        }
    }
}
