//
//  PlaylistPlayerViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI
import UIKit

extension PlaylistPlayerView {
    final class ViewModel: BaseViewModel, WatchLimitLockable {
        @Published var coordinator = Coordinator()
        @Published private(set) var selectedIndex: Int
        @Published private(set) var favoriteKeys: Set<String>
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        let playlist: IPTVPlaylist
        let player = PlayerController()

        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void
        private var hasStarted = false
        /// When the screen started being pushed, and whether it is still here (see `showPlaybackFailure`).
        private var appearedAt = Date()
        private var isOnScreen = false
        /// Long enough for a push transition to finish before anything is presented on top of it.
        private static let transitionSettle: TimeInterval = 0.6
        private var isStoppedForWatchLimitPaywall = false
        private lazy var watchLimit = WatchLimitPaywallCoordinator(lockable: self)

        var channels: [IPTVChannel] { playlist.channels }

        init(
            playlist: IPTVPlaylist,
            selectedChannel: IPTVChannel,
            onBack: @escaping () -> Void,
            favoriteStore: IPTVFavoriteChannelStore = .shared
        ) {
            self.playlist = playlist
            self.onBack = onBack
            self.favoriteStore = favoriteStore
            selectedIndex = playlist.channels.firstIndex(where: { $0.id == selectedChannel.id }) ?? 0
            favoriteKeys = favoriteStore.favoriteKeys

            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }

            player.onPlaybackStarted = { [weak self] in
                guard let self else { return }
                self.watchLimit.startWatchingIfNeeded()
                AnalyticsService.shared.log(.custom("playback_start", [
                    "source": self.playlist.source.rawValue
                ]))
            }
            player.onPlaybackStopped = { [weak self] in self?.watchLimit.pauseWatching() }
            player.onLoadFailed = { [weak self] _ in self?.showPlaybackFailure() }
        }

        deinit {
            watchLimit.reset()
        }

        // MARK: - Derived state

        var currentChannel: IPTVChannel? {
            channels.indices.contains(selectedIndex) ? channels[selectedIndex] : nil
        }

        var loadingText: String { "playlist_player_loading".localized(fallback: "Loading channel...") }
        var networkLostText: String { "playlist_player_network_lost".localized(fallback: "Lost connection") }

        func isFavorite(_ channel: IPTVChannel) -> Bool {
            favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: channel))
        }

        // MARK: - Lifecycle

        func onAppear() {
            player.isActive = true
            isOnScreen = true
            favoriteKeys = favoriteStore.favoriteKeys
            guard !hasStarted else { return }
            hasStarted = true
            appearedAt = Date()
            select(at: selectedIndex)
        }

        func onDisappear() {
            player.isActive = false
            isOnScreen = false
            if player.isFullscreen {
                player.setFullscreen(false)
            }
            // The paywall covers the screen without leaving it.
            guard !isStoppedForWatchLimitPaywall else { return }
            watchLimit.reset()
            player.cleanup()
        }

        // MARK: - Actions

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func select(at index: Int) {
            guard channels.indices.contains(index) else { return }
            selectedIndex = index
            let channel = channels[index]
            player.load(url: URL(string: channel.url).flatMap { channel.url.isEmpty ? nil : $0 }, id: channel.id)
        }

        func toggleFavorite(_ channel: IPTVChannel) {
            favoriteStore.toggle(channel)
            favoriteKeys = favoriteStore.favoriteKeys
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        /// "Next Channel" on the playback-failure dialog: wraps to the first channel after the last.
        func selectNextChannel() {
            coordinator.alert = nil
            guard !channels.isEmpty else { return }
            select(at: (selectedIndex + 1) % channels.count)
        }

        // MARK: - Playback failure

        private func showPlaybackFailure() {
            // Another modal (for instance the paywall) is already covering the screen.
            if WatchLimitPaywallCoordinator.isAnotherScreenPresented {
                toast = "playlist_player_error_message".localized(
                    fallback: "This channel cannot be played. Please try another channel."
                )
                return
            }
            // A `fullScreenCover` presented mid-push is never laid out, leaving an invisible cover
            // that swallows every touch — and a cached error fails fast enough to land there.
            let wait = max(0, Self.transitionSettle - Date().timeIntervalSince(appearedAt))
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
                guard let self, isOnScreen else { return }
                coordinator.alert = .playbackFailed
            }
        }

        // MARK: - WatchLimitLockable

        func pauseForWatchLimitPaywall() {
            if player.isFullscreen {
                player.setFullscreen(false)
            }
            isStoppedForWatchLimitPaywall = true
            player.stopKeepingRequest()
        }

        func resumeAfterWatchLimitPurchase() {
            guard isStoppedForWatchLimitPaywall else {
                player.resume()
                return
            }
            isStoppedForWatchLimitPaywall = false
            select(at: selectedIndex)
        }

        func leavePlaybackAfterWatchLimitDismiss() {
            isStoppedForWatchLimitPaywall = false
            player.cleanup()
            onBack()
        }
    }
}
