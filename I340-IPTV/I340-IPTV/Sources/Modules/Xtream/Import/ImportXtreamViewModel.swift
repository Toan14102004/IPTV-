//
//  ImportXtreamViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import UIKit

extension Notification.Name {
    /// Posted after an Xtream profile has been saved, so the Xtream tab reloads its list.
    static let xtreamProfilesDidChange = Notification.Name("xtreamProfilesDidChange")
}

extension ImportXtreamView {
    final class ViewModel: ObservableObject {
        @Published var name = ""
        @Published var serverURL = ""
        @Published var username = ""
        @Published var password = ""
        @Published var isPasswordVisible = false
        @Published private(set) var avatar = ViewModel.defaultAvatar
        /// Avatar highlighted in the sheet; becomes `avatar` on "Save Changes".
        @Published var draftAvatar = ViewModel.defaultAvatar
        @Published var isAvatarSheetPresented = false
        @Published var isPhotoPickerPresented = false
        @Published private(set) var isImporting = false
        @Published private(set) var errorMessage: String?
        @Published var isErrorPresented = false

        static let avatars: [(name: String, image: ImageAsset)] = [
            ("avatar_duck_1", Asset.Image.avatarDuck1),
            ("avatar_duck_2", Asset.Image.avatarDuck2),
            ("avatar_duck_3", Asset.Image.avatarDuck3),
            ("avatar_duck_4", Asset.Image.avatarDuck4),
            ("avatar_duck_5", Asset.Image.avatarDuck5),
            ("avatar_duck_6", Asset.Image.avatarDuck6),
            ("avatar_duck_7", Asset.Image.avatarDuck7),
            ("avatar_duck_8", Asset.Image.avatarDuck8)
        ]
        static let defaultAvatar = "avatar_duck_3"
        static let nameMaxLength = 100

        private let onBack: () -> Void
        private var importTask: Task<Void, Never>?
        private var cancellables = Set<AnyCancellable>()

        @Injected private var playlistManager: IPTVPlaylistManager

        init(onBack: @escaping () -> Void) {
            self.onBack = onBack
            $name
                .sink { [weak self] value in
                    guard value.count > Self.nameMaxLength else { return }
                    self?.name = String(value.prefix(Self.nameMaxLength))
                }
                .store(in: &cancellables)
        }

        deinit {
            importTask?.cancel()
        }

        // MARK: - Texts

        var title: String { "xtream_import_title".localized(fallback: "Xtream Codes") }
        var nameTitle: String { "import_field_name".localized(fallback: "Playlist Name") }
        var namePlaceholder: String { "import_field_name_placeholder".localized(fallback: "e.g. My Playlist") }
        var serverTitle: String { "playlist_add_server_url_label".localized(fallback: "Server URL") }
        var serverPlaceholder: String { "xtream_import_server_placeholder".localized(fallback: "https://xtream.com") }
        var serverHint: String { ".m3u/.w3u/.m3u8" }
        var usernameTitle: String { "playlist_add_username_label".localized(fallback: "Username") }
        var usernamePlaceholder: String { "playlist_add_username_placeholder".localized(fallback: "Username") }
        var passwordTitle: String { "playlist_add_password_label".localized(fallback: "Password") }
        var passwordPlaceholder: String { "playlist_add_password_placeholder".localized(fallback: "Password") }
        var howToUseTitle: String { "playlist_menu_how_to_use".localized(fallback: "How to use?") }
        var addTitle: String { "main_add_profile".localized(fallback: "Add Profile") }

        var avatarTitle: String { "playlist_add_select_avatar".localized(fallback: "Select your avatar") }
        var avatarSubtitle: String {
            "xtream_avatar_subtitle".localized(fallback: "Select a picture to customize your experience")
        }
        var cancelTitle: String { "cancel".localized(fallback: "Cancel") }
        var saveChangesTitle: String { "xtream_avatar_save".localized(fallback: "Save Changes") }

        var loadingTitle: String { "xtream_loading_title".localized(fallback: "Loading your Xtream content...") }
        var loadingMessage: String { "xtream_loading_message".localized(fallback: "Hang tight, it will be worth the wait") }
        var closeTitle: String { "playlist_loading_close".localized(fallback: "Close") }
        var failedTitle: String { "xtream_import_failed_title".localized(fallback: "Fail to Import") }
        var tryAgainTitle: String { "import_try_again".localized(fallback: "Try Again") }

        var premiumAction: (() -> Void)? {
            IAPHelper.shared().isSubscribed() ? nil : { AppNavigator.presentPaywall() }
        }

        // MARK: - State

        var canAdd: Bool {
            ![name, serverURL, username, password].contains { trimmed($0).isEmpty }
        }

        // MARK: - Actions

        func didTapBack() {
            importTask?.cancel()
            InterstitialGuard.perform { [onBack] in onBack() }
        }

        func didTapFavorites() {
            InterstitialGuard.perform { AppNavigator.push(.playlistFavorites) }
        }

        func didTapHelp() {
            InterstitialGuard.perform { AppNavigator.present(.guide) }
        }

        func didTapHowToUse() {
            AppNavigator.present(.guide)
        }

        func didTapAvatar() {
            draftAvatar = avatar
            isAvatarSheetPresented = true
        }

        func saveAvatar() {
            avatar = draftAvatar
            isAvatarSheetPresented = false
        }

        /// "+" tile: closes the sheet and opens the photo library.
        func didTapAddPhoto() {
            isAvatarSheetPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.isPhotoPickerPresented = true
            }
        }

        func didPickPhoto(_ image: UIImage?) {
            isPhotoPickerPresented = false
            guard let image, let name = XtreamAvatarStore.save(image) else { return }
            avatar = name
            draftAvatar = name
        }

        func cancelAvatar() {
            isAvatarSheetPresented = false
        }

        func didTapAdd() {
            guard canAdd, !isImporting else { return }
            let name = trimmed(name)
            let serverURL = trimmed(serverURL)
            let username = trimmed(username)
            let password = trimmed(password)
            let avatar = avatar
            let manager = playlistManager

            isImporting = true
            importTask = Task { @MainActor [weak self] in
                do {
                    _ = try await manager.saveXtreamProfile(
                        name: name,
                        serverURL: serverURL,
                        username: username,
                        password: password,
                        avatarName: avatar
                    )
                    guard let self, !Task.isCancelled else { return }
                    isImporting = false
                    NotificationCenter.default.post(name: .xtreamProfilesDidChange, object: nil)
                    onBack()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { showRateForApp() }
                } catch {
                    guard let self, !Task.isCancelled else { return }
                    Logger.e("Import Xtream failed", error)
                    isImporting = false
                    errorMessage = XtreamView.ViewModel.saveErrorMessage(error)
                    isErrorPresented = true
                }
            }
        }

        func cancelImport() {
            importTask?.cancel()
            importTask = nil
            isImporting = false
        }

        func dismissError() {
            isErrorPresented = false
        }

        func retry() {
            isErrorPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.didTapAdd() }
        }

        private func trimmed(_ value: String) -> String {
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
