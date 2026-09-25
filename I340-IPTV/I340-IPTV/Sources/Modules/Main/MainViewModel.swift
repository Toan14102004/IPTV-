//
//  MainViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension MainView {
    enum Tab: Hashable {
        case playlist
        case xtream
    }

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var selectedTab: Tab = .playlist
        /// Tabs are created the first time they are shown (like the UIKit `lazy var`s were).
        @Published private(set) var visitedTabs: Set<Tab> = [.playlist]

        let playlistViewModel = PlaylistView.ViewModel()
        let xtreamViewModel = XtreamView.ViewModel()

        private var hasCheckedAppSuspend = false

        init() {
            xtreamViewModel.onRequestAddProfile = { [weak self] in
                self?.showOverlay(.addPlaylist(mode: .xtream, owner: .xtream))
            }
        }

        // MARK: - Texts

        var playlistTitle: String { localized("main_playlist", fallback: "Playlist") }
        var xtreamTitle: String { localized("main_xtream", fallback: "Xtream") }

        // MARK: - Actions

        func onAppear() {
            guard !hasCheckedAppSuspend else { return }
            hasCheckedAppSuspend = true
            checkAppSuspend()
        }

        func select(_ tab: Tab) {
            selectedTab = tab
            visitedTabs.insert(tab)
        }

        func didTapAdd() {
            switch selectedTab {
            case .playlist: showOverlay(.addMenu)
            case .xtream: xtreamViewModel.didTapAdd()
            }
        }

        // MARK: - Add flow

        func showOverlay(_ overlay: Coordinator.Overlay) {
            withAnimation(.easeOut(duration: 0.3)) { coordinator.overlay = overlay }
        }

        /// Closes the sheet, then runs `completion` (it may open the next one).
        func closeOverlay(animated: Bool = true, completion: (() -> Void)? = nil) {
            if animated {
                withAnimation(.easeIn(duration: 0.25)) { coordinator.overlay = nil }
            } else {
                coordinator.overlay = nil
            }
            guard let completion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.28 : 0)) { completion() }
        }

        func didSelectAddOption(_ option: PlaylistAddMenuOption) {
            playlistViewModel.didSelectAddOption(option)
            switch option {
            case .importPlaylistURL: showOverlay(.addPlaylist(mode: .m3u, owner: .playlist))
            case .importXtreamCodeAPI: showOverlay(.addPlaylist(mode: .xtream, owner: .playlist))
            case .importFromDevice: showOverlay(.addPlaylist(mode: .file, owner: .playlist))
            case .playSingleStream: showOverlay(.addStream)
            }
        }

        func addProfileAction(for owner: Tab) -> AddPlaylistView.AddXtreamAction {
            switch owner {
            case .playlist:
                return { [playlistViewModel] profile in
                    await playlistViewModel.addXtreamProfile(profile)
                }
            case .xtream:
                return { [xtreamViewModel] profile in
                    await xtreamViewModel.saveProfile(profile)
                }
            }
        }

        func openStore(for appID: String) {
            coordinator.alert = nil
            Utils.openAppStore(appID)
        }

        // MARK: - Private

        private func checkAppSuspend() {
            let appID = RemoteKonfig.shared.navigateReinstall
            guard !appID.isEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.coordinator.alert = .reinstallRequired(appID: appID)
            }
        }

        private func localized(_ key: String, fallback: String) -> String {
            let value = key.localized
            return value == key || value.isEmpty ? fallback : value
        }
    }
}
