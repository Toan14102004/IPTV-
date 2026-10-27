//
//  ImportPlaylistViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation

extension ImportPlaylistView {
    enum Alert: Equatable {
        case invalidSource
        /// Stream tab only: the reachability check came back negative, confirm before saving anyway.
        case unreachableConfirm
    }

    enum URLCheck: Equatable {
        case idle
        case checking
        case reachable
        case unreachable
    }

    final class ViewModel: ObservableObject {
        @Published private(set) var tab: ImportPlaylistTab
        @Published var name = ""
        @Published var url = ""
        @Published private(set) var urlCheck = URLCheck.idle
        @Published private(set) var pickedFileURL: URL?
        @Published private(set) var isUploadingFile = false
        @Published var isFileImporterPresented = false
        @Published private(set) var isImporting = false
        @Published var alert: Alert?

        static let nameMaxLength = 100

        private let onBack: () -> Void
        private var importTask: Task<Void, Never>?
        private var checkTask: Task<Void, Never>?
        private var uploadTask: Task<Void, Never>?
        private var cancellables = Set<AnyCancellable>()

        @Injected private var playlistManager: IPTVPlaylistManager

        init(tab: ImportPlaylistTab, onBack: @escaping () -> Void) {
            self.tab = tab
            self.onBack = onBack

            $url
                .removeDuplicates()
                .sink { [weak self] _ in self?.urlCheck = .idle }
                .store(in: &cancellables)
            $url
                .removeDuplicates()
                .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
                .sink { [weak self] value in self?.checkReachability(of: value) }
                .store(in: &cancellables)
            $name
                .sink { [weak self] value in
                    guard value.count > Self.nameMaxLength else { return }
                    self?.name = String(value.prefix(Self.nameMaxLength))
                }
                .store(in: &cancellables)
        }

        deinit {
            importTask?.cancel()
            checkTask?.cancel()
            uploadTask?.cancel()
        }

        // MARK: - Texts

        var title: String { "import_title".localized(fallback: "Import Playlist") }
        func title(for tab: ImportPlaylistTab) -> String { tab.titleKey.localized(fallback: tab.fallbackTitle) }

        var nameTitle: String { "import_field_name".localized(fallback: "Playlist Name") }
        var namePlaceholder: String { "import_field_name_placeholder".localized(fallback: "e.g. My Playlist") }
        /// Files and streams fall back to their own name.
        var isNameRequired: Bool { tab == .playlist }

        var urlTitle: String {
            tab == .stream
                ? "import_field_stream".localized(fallback: "Stream URL")
                : "import_field_url".localized(fallback: "Playlist URL")
        }

        var urlPlaceholder: String {
            tab == .stream
                ? "import_field_stream_placeholder".localized(fallback: "e.g. https://example.com/live.m3u8")
                : "import_field_url_placeholder".localized(fallback: "e.g. https://esport.iptv/index.m3u")
        }

        var urlHint: String {
            switch urlCheck {
            case .reachable: "import_field_url_valid".localized(fallback: "URL is valid and accessible")
            case .unreachable: "import_field_url_unreachable".localized(fallback: "We couldn't reach this URL")
            case .idle, .checking:
                tab == .stream ? ".m3u8/.mp4/.ts" : ".m3u/.w3u/.m3u8"
            }
        }

        var urlStatus: FormFieldStatus {
            switch urlCheck {
            case .reachable: .valid
            case .unreachable: .invalid
            case .idle, .checking: .normal
            }
        }

        var fileTitle: String { "import_field_upload_file".localized(fallback: "Upload File") }
        var selectFileTitle: String { "import_select_file".localized(fallback: "Select file") }
        var uploadingTitle: String { "import_uploading".localized(fallback: "Uploading...") }
        var fileHint: String { ".m3u/.w3u/.m3u8" }
        var pickedFileName: String? { pickedFileURL?.lastPathComponent }

        var howToUseTitle: String { "playlist_menu_how_to_use".localized(fallback: "How to use?") }
        var addTitle: String { "playlist_add_playlist".localized(fallback: "Add Playlist") }

        var invalidTitle: String { "import_invalid_title".localized(fallback: "Invalid Playlist Source") }
        /// Set from the failing error so, e.g., a duplicate URL says so instead of a generic message.
        private(set) var invalidMessage = ""
        var cancelTitle: String { "cancel".localized(fallback: "Cancel") }
        var tryAgainTitle: String { "import_try_again".localized(fallback: "Try Again") }

        var unreachableTitle: String { "import_unreachable_title".localized(fallback: "Link May Not Work") }
        var unreachableMessage: String {
            "import_unreachable_message".localized(
                fallback: "We couldn’t confirm this link responds right now. You can still add it — playback will tell you if it doesn’t work."
            )
        }
        var saveAnywayTitle: String { "import_save_anyway".localized(fallback: "Add Anyway") }

        var premiumAction: (() -> Void)? {
            IAPHelper.shared().isSubscribed() ? nil : { AppNavigator.presentPaywall() }
        }

        // MARK: - State

        /// The form is complete (the reachability check only informs, it does not block).
        var canAdd: Bool {
            switch tab {
            case .playlist: !trimmed(name).isEmpty && Self.isWebURL(trimmed(url))
            case .stream: Self.isWebURL(trimmed(url))
            case .file: pickedFileURL != nil && !isUploadingFile
            }
        }

        var isAddEnabled: Bool { canAdd || isImporting }

        // MARK: - Actions

        func select(_ tab: ImportPlaylistTab) {
            guard tab != self.tab, !isImporting else { return }
            self.tab = tab
            checkReachability(of: url)
        }

        func didTapBack() {
            importTask?.cancel()
            InterstitialGuard.perform { [onBack] in onBack() }
        }

        func didTapHelp() {
            InterstitialGuard.perform { AppNavigator.present(.guide) }
        }

        func didTapHowToUse() {
            AppNavigator.present(.guide)
        }

        func didTapChooseFile() {
            isFileImporterPresented = true
        }

        /// Copies the picked file into the app first, so it stays readable after the picker closes.
        func didPickFile(_ result: Result<URL, Error>) {
            guard case let .success(fileURL) = result else { return }
            clearPickedFile()
            isUploadingFile = true
            uploadTask = Task { @MainActor [weak self] in
                let copy = await Task.detached { Self.copyToStaging(fileURL) }.value
                guard let self, !Task.isCancelled else { return }
                isUploadingFile = false
                if let copy {
                    pickedFileURL = copy
                } else {
                    alert = .invalidSource
                }
            }
        }

        func clearPickedFile() {
            uploadTask?.cancel()
            isUploadingFile = false
            if let pickedFileURL {
                try? FileManager.default.removeItem(at: pickedFileURL)
            }
            pickedFileURL = nil
        }

        func didTapAdd() {
            guard canAdd, !isImporting else { return }
            // Streams skip content validation, so the reachability hint is all we have.
            if tab == .stream, urlCheck == .unreachable {
                alert = .unreachableConfirm
                return
            }
            performAdd()
        }

        func confirmAddAnyway() {
            alert = nil
            performAdd()
        }

        func retry() {
            alert = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.didTapAdd() }
        }

        func dismissAlert() {
            alert = nil
        }

        private func performAdd() {
            let manager = playlistManager
            let name = trimmed(name)
            let url = trimmed(url)

            switch tab {
            case .playlist:
                runImport { try await manager.importRemotePlaylist(name: name, url: url) }
            case .stream:
                runImport { try await manager.importSingleStream(name: name.isEmpty ? nil : name, url: url) }
            case .file:
                guard let fileURL = pickedFileURL else { return }
                runImport { try await manager.importLocalFile(fileURL: fileURL, name: name.isEmpty ? nil : name) }
            }
        }

        // MARK: - Private

        private func runImport(_ work: @escaping () async throws -> IPTVPlaylist) {
            isImporting = true
            importTask = Task { @MainActor [weak self] in
                do {
                    let playlist = try await work()
                    guard let self, !Task.isCancelled else { return }
                    isImporting = false
                    finish(with: playlist)
                } catch {
                    guard let self, !Task.isCancelled else { return }
                    Logger.e("Import failed", error)
                    isImporting = false
                    invalidMessage = IPTVPlaylistError.message(for: error)
                    alert = .invalidSource
                }
            }
        }

        private func finish(with playlist: IPTVPlaylist) {
            AnalyticsService.shared.log(.custom("import_playlist", [
                "source": playlist.source.rawValue,
                "channels": playlist.channels.count
            ]))
            if let pickedFileURL {
                try? FileManager.default.removeItem(at: pickedFileURL)
            }
            onBack()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // A file or single stream lands in the VIDEOS section of the Playlist tab; links open their channels.
                if playlist.source != .file, playlist.source != .stream {
                    AppNavigator.push(.playlistChannels(playlist: playlist))
                }
                if !playlist.channels.isEmpty, playlist.source != .stream {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showRateForApp() }
                }
            }
        }

        /// Asks the server whether the URL answers (HEAD, then a 1-byte GET for servers that refuse HEAD).
        private func checkReachability(of value: String) {
            checkTask?.cancel()
            let value = trimmed(value)
            guard tab != .file, let target = URL(string: value), Self.isWebURL(value) else {
                urlCheck = .idle
                return
            }

            urlCheck = .checking
            checkTask = Task { @MainActor [weak self] in
                let isReachable = await Self.isReachable(target)
                guard let self, !Task.isCancelled, trimmed(url) == value else { return }
                urlCheck = isReachable ? .reachable : .unreachable
            }
        }

        private static func isReachable(_ url: URL) async -> Bool {
            for method in ["HEAD", "GET"] {
                var request = URLRequest(url: url, timeoutInterval: 8)
                request.httpMethod = method
                if method == "GET" { request.setValue("bytes=0-0", forHTTPHeaderField: "Range") }
                guard let (_, response) = try? await URLSession.shared.data(for: request),
                      let status = (response as? HTTPURLResponse)?.statusCode else { continue }
                if (200..<400).contains(status) { return true }
            }
            return false
        }

        private static func copyToStaging(_ sourceURL: URL) -> URL? {
            let didAccess = sourceURL.startAccessingSecurityScopedResource()
            defer { if didAccess { sourceURL.stopAccessingSecurityScopedResource() } }

            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            let destination = directory.appendingPathComponent(sourceURL.lastPathComponent)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: sourceURL, to: destination)
                return destination
            } catch {
                return nil
            }
        }

        private static func isWebURL(_ value: String) -> Bool {
            guard let url = URL(string: value),
                  let scheme = url.scheme?.lowercased(),
                  ["http", "https"].contains(scheme) else { return false }
            return url.host?.isEmpty == false
        }

        private func trimmed(_ value: String) -> String {
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
