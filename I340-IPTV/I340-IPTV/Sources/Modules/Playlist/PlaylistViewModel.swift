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
        @Published private(set) var selectedOption: PlaylistOption = .playlistURL
        @Published private(set) var isLoading = false
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        let options = PlaylistOption.allCases

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

        var filteredPlaylists: [IPTVPlaylist] {
            playlists.filter { playlist in
                switch selectedOption {
                case .playlistURL: playlist.source == .playlistURL
                case .file: playlist.source == .file
                case .stream: playlist.source == .stream
                case .favorite: false
                }
            }
        }

        func title(for option: PlaylistOption) -> String {
            localized(option.titleKey, fallback: option.fallbackTitle)
        }

        var screenTitle: String { localized("main_playlist", fallback: "Playlist") }
        var emptyTitle: String { localized("main_no_playlists", fallback: "No playlists yet") }
        var emptySubtitle: String { localized("main_tap_add_playlist", fallback: "Tap the Add button to create one.") }

        func subtitle(for playlist: IPTVPlaylist) -> String {
            let locale = currentAppLocale()
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.unitsStyle = .full
            let updatedText = formatter.localizedString(for: playlist.updatedAt, relativeTo: Date())
            let channelFormat = localized("playlist_channels_count", fallback: "%d channels")
            let channelText = String(format: channelFormat, locale: locale, playlist.channels.count)
            return "\(localized("playlist_updated", fallback: "Updated")) \(updatedText) • \(channelText)"
        }

        // MARK: - Lifecycle & header

        func onAppear() {
            Task { @MainActor [weak self] in
                await self?.reloadPlaylists()
            }
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

        // MARK: - List

        func select(_ option: PlaylistOption) {
            if option == .favorite {
                AppNavigator.push(.playlistFavorites)
                return
            }
            selectedOption = option
        }

        func open(_ playlist: IPTVPlaylist) {
            AppNavigator.push(.playlistChannels(playlist: playlist))
        }

        func showMenu(for playlist: IPTVPlaylist) {
            coordinator.actionMenuID = playlist.id
        }

        func closeMenu() {
            coordinator.actionMenuID = nil
        }

        func menuItems(for playlist: IPTVPlaylist) -> [ActionMenuItem] {
            [
                ActionMenuItem(
                    title: localized("playlist_action_rename", fallback: "Rename"),
                    systemImage: "square.and.pencil"
                ) { [weak self] in self?.coordinator.rename = playlist },
                ActionMenuItem(
                    title: localized("playlist_action_delete", fallback: "Delete"),
                    systemImage: "trash"
                ) { [weak self] in self?.coordinator.alert = .deletePlaylist(playlist) }
            ]
        }

        func rename(_ playlist: IPTVPlaylist, to name: String) {
            coordinator.rename = nil
            let newName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !newName.isEmpty else {
                toast = localized("playlist_rename_empty_error", fallback: "The name cannot be left blank.")
                return
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    _ = try await playlistManager.updatePlaylistName(id: playlist.id, name: newName)
                    await reloadPlaylists()
                } catch {
                    toast = IPTVPlaylistError.message(for: error)
                }
            }
        }

        func delete(_ playlist: IPTVPlaylist) {
            coordinator.alert = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await playlistManager.deletePlaylist(id: playlist.id)
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

        // MARK: - Add flow (the sheets are shown by `MainView`)

        /// The chosen "add" option also selects the matching chip.
        func didSelectAddOption(_ option: PlaylistAddMenuOption) {
            if let playlistOption = option.relatedPlaylistOption {
                selectedOption = playlistOption
            }
        }

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
            selectedOption = playlist.source.playlistOption
            toast = playlist.channels.isEmpty
                ? localized("playlist_add_empty_channels_warning", fallback: "The playlist contains no channels.")
                : localized("playlist_add_success", fallback: "Playlist imported successfully.")
            open(playlist)
            if !playlist.channels.isEmpty, playlist.source != .stream {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showRateForApp()
                }
            }
        }

        // MARK: - Private

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

        private func currentAppLocale() -> Locale {
            let appLanguage = UserDefaultManager.shared().appLanguage
            return Locale(identifier: appLanguage.isEmpty ? Locale.current.identifier : appLanguage)
        }
    }
}

private extension IPTVPlaylistSource {
    var playlistOption: PlaylistOption {
        switch self {
        case .file: .file
        case .stream: .stream
        case .playlistURL, .clipboard, .xtream, .unknown: .playlistURL
        }
    }
}
