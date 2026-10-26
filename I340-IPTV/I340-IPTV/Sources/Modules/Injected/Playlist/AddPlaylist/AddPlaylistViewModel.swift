//
//  AddPlaylistViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension AddPlaylistView {
    /// Saves an Xtream profile; returns an error message, nil on success.
    typealias AddXtreamAction = (XtreamProfileItem) async -> String?

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var mode: AddPlaylistMode
        @Published var name = ""
        @Published var playlistURL = ""
        @Published var serverURL = ""
        @Published var username = ""
        @Published var password = ""
        @Published var isPasswordVisible = false
        @Published var isAgreementSelected = false
        @Published var isFileImporterPresented = false
        @Published private(set) var selectedAvatar = ViewModel.defaultAvatar
        @Published private(set) var pickedFileName: String?
        @Published private(set) var isSubmitting = false

        static let avatars: [(name: String, image: ImageAsset)] = [
            ("avatar_xtream_1", Asset.Image.avatarXtream1),
            ("avatar_xtream_2", Asset.Image.avatarXtream2),
            ("avatar_xtream_3", Asset.Image.avatarXtream3),
            ("avatar_xtream_4", Asset.Image.avatarXtream4)
        ]
        static let defaultAvatar = "avatar_xtream_2"
        static let nameMaxLength = 100
        static let licenseURL = "https://vananhtien.com/iptv/terms/"

        private let onAddPlaylist: AddXtreamAction?
        private let onSubmit: ((PlaylistAddChannelSubmission) -> Void)?
        private let dismissScreen: (_ animated: Bool, _ completion: (() -> Void)?) -> Void
        private var addTask: Task<Void, Never>?

        init(
            mode: AddPlaylistMode,
            onAddPlaylist: AddXtreamAction?,
            onSubmit: ((PlaylistAddChannelSubmission) -> Void)?,
            dismiss: @escaping (_ animated: Bool, _ completion: (() -> Void)?) -> Void
        ) {
            self.mode = mode
            self.onAddPlaylist = onAddPlaylist
            self.onSubmit = onSubmit
            self.dismissScreen = dismiss
        }

        // MARK: - Texts

        var tabTitles: [String] { AddPlaylistMode.allCases.map { $0.segmentTitleKey.localized } }
        var selectedTabIndex: Int { AddPlaylistMode.allCases.firstIndex(of: mode) ?? 0 }
        var title: String { mode.titleKey.localized }

        var primaryTitle: String { pickedFileName ?? mode.primaryTitleKey.localized }
        var primaryFontSize: CGFloat { mode == .file ? 12 : 16 }

        var licenseText: String {
            "playlist_add_license_agreement".localized
                .replacingOccurrences(of: "License Agreement", with: "License\nAgreement")
        }

        // MARK: - Actions

        func selectTab(_ index: Int) {
            guard AddPlaylistMode.allCases.indices.contains(index) else { return }
            mode = AddPlaylistMode.allCases[index]
        }

        func selectAvatar(_ name: String) {
            selectedAvatar = name
        }

        func limitName(_ value: String) {
            if value.count > Self.nameMaxLength {
                name = String(value.prefix(Self.nameMaxLength))
            }
        }

        func didTapBack() {
            InterstitialGuard.perform { [weak self] in
                self?.dismissScreen(true, nil)
            }
        }

        func didTapHowToUse() {
            AppNavigator.present(.guide)
        }

        func openLicense() {
            AppNavigator.present(.web(url: Self.licenseURL))
        }

        func toggleAgreement() {
            isAgreementSelected.toggle()
        }

        func didTapAdd() {
            guard !isSubmitting else { return }
            guard isAgreementSelected else {
                showMessage("playlist_add_agreement_required_error".localized)
                return
            }

            switch mode {
            case .m3u: submitM3U()
            case .file:
                isSubmitting = true
                isFileImporterPresented = true
            case .xtream: submitXtream()
            }
        }

        func didPickFile(_ result: Result<URL, Error>) {
            guard case let .success(fileURL) = result else {
                isSubmitting = false
                return
            }
            pickedFileName = fileURL.lastPathComponent
            let name = trimmed(name)
            dismissScreen(true) { [onSubmit] in
                onSubmit?(.file(name: name, fileURL: fileURL))
            }
        }

        func fileImporterDismissedWithoutPick() {
            if pickedFileName == nil { isSubmitting = false }
        }

        func cancelXtreamImport() {
            addTask?.cancel()
            addTask = nil
            isSubmitting = false
            coordinator.alert = nil
        }

        func closeFailedDialog() {
            coordinator.alert = nil
        }

        func dismissMessage() {
            coordinator.alert = nil
        }

        // MARK: - Submission

        private func submitM3U() {
            let name = trimmed(name)
            let url = trimmed(playlistURL)

            guard !name.isEmpty, !url.isEmpty else {
                showMessage("playlist_add_name_url_empty_error".localized)
                return
            }
            guard let resolvedURL = URL(string: url),
                  let scheme = resolvedURL.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  resolvedURL.host?.isEmpty == false else {
                showMessage("playlist_add_invalid_or_empty_error".localized)
                return
            }
            dismissScreen(true) { [onSubmit] in
                onSubmit?(.m3u(name: name, url: url))
            }
        }

        private func submitXtream() {
            let name = trimmed(name)
            let serverURL = trimmed(serverURL)
            let username = trimmed(username)
            let password = trimmed(password)

            if name.isEmpty { return showMessage("playlist_add_name_empty_error".localized) }
            if serverURL.isEmpty { return showMessage("playlist_add_server_url_empty_error".localized) }
            if username.isEmpty { return showMessage("playlist_add_username_empty_error".localized) }
            if password.isEmpty { return showMessage("playlist_add_password_empty_error".localized) }
            guard let onAddPlaylist else {
                return showMessage("playlist_add_xtream_flow_error".localized)
            }

            let profile = XtreamProfileItem(
                name: name,
                profileID: username,
                serverURL: serverURL,
                password: password,
                avatarName: selectedAvatar,
                updatedText: "playlist_updated_moment_ago".localized
            )
            isSubmitting = true
            coordinator.alert = .xtreamLoading

            addTask = Task { @MainActor [weak self] in
                let errorMessage = await onAddPlaylist(profile)
                guard let self, !Task.isCancelled else { return }
                addTask = nil
                isSubmitting = false
                if errorMessage == nil {
                    coordinator.alert = nil
                    dismissScreen(true) { showRateForApp() }
                } else {
                    coordinator.alert = .xtreamFailed
                }
            }
        }

        // MARK: - Private

        private func showMessage(_ message: String) {
            coordinator.alert = .message(message)
        }

        private func trimmed(_ value: String) -> String {
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
