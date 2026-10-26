//
//  ContentViewModel.swift
//  I340_IPTV
//
//  Created by Toan Nguyen on 26/9/25.
//

import Combine
import Foundation
import SwiftUI

extension ContentView {
    enum Tab: Hashable {
        case playlist
        case hub
        case xtream
        case settings
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
            // The Xtream tab only ever adds Xtream profiles, so it skips the "Choose Import"
            // sheet and goes straight to the Xtream form; the Playlist tab offers all import
            // kinds, so it shows the sheet first.
            xtreamViewModel.onRequestAddProfile = {
                AppNavigator.push(.importXtream)
            }
            playlistViewModel.onRequestAdd = { [weak self] in
                self?.showOverlay(.addMenu)
            }
        }

        // MARK: - Texts

        func title(for tab: Tab) -> String {
            switch tab {
            case .playlist: localized("main_playlist", fallback: "Playlist")
            case .hub: localized("main_hub", fallback: "Room")
            case .xtream: localized("main_xtream", fallback: "Xtream")
            case .settings: localized("settings", fallback: "Settings")
            }
        }

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
            case .xtream: xtreamViewModel.didTapAdd()
            case .playlist:
                showOverlay(.addMenu)
            case .hub, .settings:
                // What gets added lands in Playlist, so show it behind the menu.
                select(.playlist)
                showOverlay(.addMenu)
            }
        }

        // MARK: - Add flow

        func showOverlay(_ overlay: Coordinator.Overlay) {
            withAnimation(.easeOut(duration: 0.3)) { coordinator.overlay = overlay }
        }

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
            switch option {
            case .importPlaylistURL: AppNavigator.push(.importPlaylist(tab: .playlist))
            case .importFromDevice: AppNavigator.push(.importPlaylist(tab: .file))
            case .playSingleStream: AppNavigator.push(.importPlaylist(tab: .stream))
            case .importXtreamCodeAPI: AppNavigator.push(.importXtream)
            }
        }

        func addProfileAction(for owner: Tab) -> AddPlaylistView.AddXtreamAction {
            switch owner {
            case .playlist:
                return { [playlistViewModel] profile in
                    await playlistViewModel.addXtreamProfile(profile)
                }
            case .xtream, .hub, .settings:
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
