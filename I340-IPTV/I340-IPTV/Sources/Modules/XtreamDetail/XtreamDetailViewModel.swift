//
//  XtreamDetailViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI
import UIKit

extension XtreamDetailView {
    final class ViewModel: BaseViewModel, WatchLimitLockable {
        @Published var coordinator = Coordinator()
        @Published private(set) var currentChannel: IPTVChannel
        @Published private(set) var favoriteKeys: Set<String>
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        /// The channels listed under the player (all but the one that was opened).
        let related: [IPTVChannel]
        let player = PlayerController()

        let aspectOptions: [DetailXtreamAspectRatioOption] = [
            .default, .cropToFill,
            .ratio(4.0 / 3.0), .ratio(5.0 / 4.0), .ratio(16.0 / 9.0), .ratio(9.0 / 16.0),
            .ratio(16.0 / 10.0), .ratio(2.21), .ratio(2.35), .ratio(2.39)
        ]
        let speedOptions: [(title: String, rate: Float)] = [
            ("0.25 x", 0.25), ("0.5 x", 0.5), ("0.75 x", 0.75), ("1.0 x", 1.0),
            ("1.25 x", 1.25), ("1.5 x", 1.5), ("1.75 x", 1.75), ("2.0 x", 2.0)
        ]
        let qualityOptions: [(title: String, bitRate: Double)] = [
            ("Auto", 0),
            ("1280x720 ~2 MBit/s", 2_000_000),
            ("320x184 ~246 KBit/s", 246_000),
            ("512x288 ~460 KBit/s Single Stream", 460_000),
            ("848x480 ~836 KBit/s", 836_000),
            ("1920x1080 ~6 MBit/s", 6_000_000)
        ]

        private let playlistID: String?
        private let favoriteStore: IPTVFavoriteChannelStore
        private let onBack: () -> Void
        private var hasStarted = false
        private var isStoppedForWatchLimitPaywall = false
        private var resolveTask: Task<Void, Never>?
        private lazy var watchLimit = WatchLimitPaywallCoordinator(lockable: self)

        init(
            channel: IPTVChannel,
            relatedChannels: [IPTVChannel],
            playlistID: String?,
            onBack: @escaping () -> Void,
            favoriteStore: IPTVFavoriteChannelStore = .shared
        ) {
            currentChannel = channel
            related = relatedChannels.filter { $0.id != channel.id }
            self.playlistID = playlistID
            self.onBack = onBack
            self.favoriteStore = favoriteStore
            favoriteKeys = playlistID.map { favoriteStore.favoriteKeySet(in: $0) } ?? favoriteStore.favoriteKeys

            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }

            player.onPlaybackStarted = { [weak self] in self?.watchLimit.startWatchingIfNeeded() }
            player.onPlaybackStopped = { [weak self] in self?.watchLimit.pauseWatching() }
        }

        deinit {
            resolveTask?.cancel()
            watchLimit.reset()
        }

        // MARK: - Derived state

        var loadingText: String { "playlist_player_loading".localized(fallback: "Loading channel...") }
        var networkLostText: String { "playlist_player_network_lost".localized(fallback: "Lost connection") }

        var categoryText: String {
            let group = currentChannel.groupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return group.isEmpty ? "Movies" : group
        }

        func isFavorite(_ channel: IPTVChannel) -> Bool {
            favoriteKeys.contains(IPTVFavoriteChannelStore.favoriteKey(for: channel))
        }

        // MARK: - Lifecycle

        func onAppear() {
            player.isActive = true
            refreshFavorites()
            guard !hasStarted else { return }
            hasStarted = true
            play(currentChannel)
        }

        func onDisappear() {
            player.isActive = false
            if player.isFullscreen {
                player.setFullscreen(false)
            }
            // The paywall covers the screen without leaving it.
            guard !isStoppedForWatchLimitPaywall else { return }
            resolveTask?.cancel()
            watchLimit.reset()
            player.cleanup()
        }

        // MARK: - Actions

        func didTapBack() {
            InterstitialGuard.perform { [weak self] in
                self?.resolveTask?.cancel()
                self?.player.cleanup()
                self?.onBack()
            }
        }

        func play(_ channel: IPTVChannel) {
            resolveTask?.cancel()
            currentChannel = channel

            guard let url = XtreamStreamResolver.isValidStreamURL(channel.url) else {
                player.load(url: nil, id: channel.id)
                return
            }
            guard XtreamStreamResolver.isSeriesInfoURL(url) else {
                player.load(url: url, id: channel.id)
                return
            }

            player.cleanup()
            resolveTask = Task { @MainActor [weak self] in
                do {
                    let episodeURL = try await XtreamStreamResolver.firstEpisodeURL(from: url)
                    guard !Task.isCancelled, let self, currentChannel.id == channel.id else { return }
                    player.load(url: episodeURL, id: channel.id)
                } catch {
                    guard !Task.isCancelled, let self else { return }
                    toast = XtreamStreamResolver.message(for: error)
                    player.load(url: nil, id: channel.id)
                }
            }
        }

        func retry() {
            play(currentChannel)
        }

        func toggleFavorite(_ channel: IPTVChannel) {
            if let playlistID {
                favoriteStore.toggle(channel, in: playlistID)
            } else {
                favoriteStore.toggle(channel)
            }
            refreshFavorites()
        }

        // MARK: - Options

        func showMore() {
            player.showControls(autoHide: player.isPlaying)
            coordinator.alert = .more
        }

        func openOption(_ alert: Coordinator.Alert) {
            coordinator.alert = nil
            // The "more" sheet slides out before the next one comes in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.coordinator.alert = alert
            }
        }

        func dismissSheet() {
            coordinator.alert = nil
        }

        func selectSpeed(_ rate: Float) {
            coordinator.alert = nil
            player.setPlaybackRate(rate)
        }

        func selectQuality(_ bitRate: Double) {
            coordinator.alert = nil
            player.setQualityBitRate(bitRate)
        }

        func selectAspect(_ option: DetailXtreamAspectRatioOption) {
            coordinator.alert = nil
            player.setAspect(option)
        }

        // MARK: - Private

        private func refreshFavorites() {
            favoriteKeys = playlistID.map { favoriteStore.favoriteKeySet(in: $0) } ?? favoriteStore.favoriteKeys
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
            play(currentChannel)
        }

        func leavePlaybackAfterWatchLimitDismiss() {
            isStoppedForWatchLimitPaywall = false
            resolveTask?.cancel()
            player.cleanup()
            onBack()
        }
    }
}
