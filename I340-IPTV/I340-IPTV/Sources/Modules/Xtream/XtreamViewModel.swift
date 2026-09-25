//
//  XtreamViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension XtreamView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var profiles: [XtreamProfileItem] = []
        /// Content of the opened profile; replaces the profile list while it is set.
        @Published private(set) var content: XtreamContentView.ViewModel?
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        @Injected private var playlistManager: IPTVPlaylistManager

        init() {
            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        // MARK: - Texts

        var screenTitle: String { "main_xtream".localized(fallback: "Xtream") }

        // MARK: - Lifecycle & header

        func onAppear() {
            guard profiles.isEmpty else { return }
            loadProfiles()
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

        // MARK: - Add profile

        /// Opens the "add profile" form (shown by `MainView`).
        var onRequestAddProfile: (() -> Void)?

        func didTapAdd() {
            onRequestAddProfile?()
        }

        func didTapAddButton() {
            InterstitialGuard.perform { [weak self] in self?.didTapAdd() }
        }

        // MARK: - Profile menu

        func showMenu(for profile: XtreamProfileItem) {
            coordinator.actionMenuID = profile.id
        }

        func closeMenu() {
            coordinator.actionMenuID = nil
        }

        func menuItems(for profile: XtreamProfileItem) -> [ActionMenuItem] {
            [
                ActionMenuItem(
                    title: "playlist_action_rename".localized(fallback: "Rename"),
                    systemImage: "square.and.pencil"
                ) { [weak self] in self?.coordinator.rename = profile },
                ActionMenuItem(
                    title: "playlist_action_delete".localized(fallback: "Delete"),
                    systemImage: "trash"
                ) { [weak self] in self?.coordinator.alert = .deleteProfile(profile) }
            ]
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        // MARK: - Open a profile

        func open(_ profile: XtreamProfileItem) {
            coordinator.alert = .disclaimer(profile)
        }

        func continueWithDisclaimer(for profile: XtreamProfileItem) {
            coordinator.alert = nil
            let contentViewModel = XtreamContentView.ViewModel(
                profileName: profile.name,
                avatarName: profile.avatarName,
                profileID: profile.id,
                onBack: { [weak self] in self?.closeContent() }
            )
            content = contentViewModel

            Task { @MainActor [weak self, weak contentViewModel] in
                guard let self, let contentViewModel else { return }
                do {
                    let playlist = try await playlistManager.getPlaylist(id: profile.id)
                    guard content === contentViewModel else { return }
                    guard let playlist else {
                        toast = "Xtream profile not found"
                        return
                    }
                    contentViewModel.update(with: playlist)
                } catch {
                    guard content === contentViewModel else { return }
                    toast = error.localizedDescription
                }
            }
        }

        private func closeContent() {
            content = nil
            loadProfiles()
        }

        // MARK: - Rename / delete

        func rename(_ profile: XtreamProfileItem, to name: String) {
            coordinator.rename = nil
            let newName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !newName.isEmpty else {
                toast = "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank.")
                return
            }
            guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

            let previousName = profile.name
            profiles[index].name = newName

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let updated = try await playlistManager.updatePlaylistName(id: profile.id, name: newName)
                    guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
                    profiles[index] = makeProfileItem(from: updated)
                } catch {
                    if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                        profiles[index].name = previousName
                    }
                    toast = Self.saveErrorMessage(error)
                }
            }
        }

        func delete(_ profile: XtreamProfileItem) {
            coordinator.alert = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await playlistManager.deletePlaylist(id: profile.id)
                    profiles.removeAll { $0.id == profile.id }
                } catch {
                    toast = Self.saveErrorMessage(error)
                }
            }
        }

        // MARK: - Private

        private func loadProfiles() {
            Task { @MainActor [weak self] in
                guard let self, let playlists = try? await playlistManager.getPlaylistSummaries() else { return }
                profiles = playlists
                    .filter { $0.source == .xtream }
                    .map { self.makeProfileItem(from: $0) }
            }
        }

        /// Saves a profile typed in the add form; returns an error message, nil on success.
        func saveProfile(_ profile: XtreamProfileItem) async -> String? {
            do {
                _ = try await playlistManager.saveXtreamProfile(
                    name: profile.name,
                    serverURL: profile.serverURL,
                    username: profile.profileID,
                    password: profile.password,
                    avatarName: profile.avatarName
                )
                loadProfiles()
                return nil
            } catch {
                switch error {
                case IPTVPlaylistError.duplicateName, IPTVPlaylistError.duplicateURL:
                    loadProfiles()
                default:
                    break
                }
                return Self.saveErrorMessage(error)
            }
        }

        private func makeProfileItem(from playlist: IPTVPlaylist) -> XtreamProfileItem {
            let payload = XtreamProfilePayload.decode(from: playlist.url)
            return XtreamProfileItem(
                id: playlist.id,
                name: playlist.name,
                profileID: payload.username.isEmpty ? playlist.id : payload.username,
                serverURL: payload.serverURL.isEmpty ? playlist.url : payload.serverURL,
                password: payload.password,
                avatarName: payload.avatarName,
                updatedText: Self.accountUpdateText(from: playlist.createdAt)
            )
        }

        private static func accountUpdateText(from date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return String(format: "xtream_account_update_on_format".localized, formatter.string(from: date))
        }

        private static func saveErrorMessage(_ error: Error) -> String {
            switch error {
            case IPTVPlaylistError.emptyName:
                return "playlist_add_name_empty_error".localized
            case IPTVPlaylistError.emptyURL:
                return "xtream_information_empty_error".localized
            case IPTVPlaylistError.invalidURL:
                return "playlist_add_server_url_invalid_error".localized
            case IPTVPlaylistError.duplicateName:
                return "playlist_add_duplicate_name_error".localized
            case IPTVPlaylistError.duplicateURL:
                return "xtream_duplicate_profile_error".localized
            case IPTVPlaylistError.emptyPlaylist:
                return "xtream_empty_content_error".localized
            case IPTVPlaylistError.xtreamAccessDenied:
                return "playlist_add_xtream_access_denied_error".localized
            case let urlError as URLError:
                switch urlError.code {
                case .cancelled:
                    return "xtream_import_cancelled".localized
                case .notConnectedToInternet:
                    return "no_internet_message".localized
                case .timedOut:
                    return "xtream_server_timeout".localized
                default:
                    return String(format: "xtream_connect_server_error_format".localized, urlError.localizedDescription)
                }
            case is DecodingError:
                return "xtream_unsupported_response_error".localized
            default:
                let message = error.localizedDescription
                return message.isEmpty ? "xtream_add_profile_error".localized : message
            }
        }
    }
}
