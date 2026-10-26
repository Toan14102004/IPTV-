//
//  PlaylistListViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation

extension PlaylistListView {
    final class ViewModel: ObservableObject {
        @Published private(set) var playlists: [IPTVPlaylist] = []
        @Published private(set) var favoriteIDs = Set(UserDefaultManager.shared().favoritePlaylistIDs)
        @Published var searchText = ""
        @Published var deleting: IPTVPlaylist?
        @Published var toast: String?

        let section: PlaylistSection
        private let onBack: () -> Void

        @Injected private var playlistManager: IPTVPlaylistManager

        init(section: PlaylistSection, onBack: @escaping () -> Void) {
            self.section = section
            self.onBack = onBack
        }

        // MARK: - Texts

        var title: String {
            section.screenTitleKey.localized(fallback: section == .playlists ? "Playlist" : "Videos")
        }

        var emptyTitle: String {
            searchText.isEmpty
                ? "playlist_empty_title".localized(fallback: "You don't have any playlists")
                : "playlist_search_no_result".localized(fallback: "No playlists found")
        }

        var premiumAction: (() -> Void)? {
            IAPHelper.shared().isSubscribed() ? nil : { AppNavigator.presentPaywall() }
        }

        // MARK: - State

        var items: [IPTVPlaylist] {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return playlists.filter { playlist in
                section.contains(playlist)
                    && (query.isEmpty || playlist.name.localizedCaseInsensitiveContains(query))
            }
        }

        func isFavorite(_ playlist: IPTVPlaylist) -> Bool {
            favoriteIDs.contains(playlist.id)
        }

        // MARK: - Actions

        func onAppear() {
            favoriteIDs = Set(UserDefaultManager.shared().favoritePlaylistIDs)
            Task { @MainActor [weak self] in await self?.reload() }
        }

        func didTapBack() {
            InterstitialGuard.perform { [onBack] in onBack() }
        }

        func didTapAddFile() {
            AppNavigator.push(.importPlaylist(tab: .file))
        }

        func open(_ playlist: IPTVPlaylist) {
            AppNavigator.push(playlist.opensPlayerDirectly ? .playVideo(playlist: playlist) : .playlistChannels(playlist: playlist))
        }

        func toggleFavorite(_ playlist: IPTVPlaylist) {
            favoriteIDs = PlaylistFavorites.toggle(playlist.id)
        }

        func cancelDelete() {
            deleting = nil
        }

        func delete(_ playlist: IPTVPlaylist) {
            deleting = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await playlistManager.deletePlaylist(id: playlist.id)
                    favoriteIDs = PlaylistFavorites.remove(playlist.id)
                    await reload()
                    toast = "playlist_delete_success".localized(fallback: "Playlist deleted successfully.")
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        // MARK: - Private

        @MainActor
        private func reload() async {
            do {
                playlists = try await playlistManager.getPlaylists()
            } catch {
                Logger.e("Loading playlists failed", error)
                toast = IPTVPlaylistError.message(for: error)
            }
        }
    }
}
