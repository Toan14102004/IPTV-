//
//  PlayVideoViewModel.swift
//  I340_IPTV
//

import AVFoundation
import Combine
import Foundation
import UIKit

extension PlayVideoView {
    enum Sheet: Hashable {
        case speed
        case audioOutput
        case invite
        case people
    }

    enum RoomState: Equatable {
        case idle
        case creating
        case hosting
    }

    /// Progress of the server's relay, which the host also plays from.
    enum RelayState: Equatable {
        case none
        case preparing
        case ready
        case failed
    }

    struct Banner: Identifiable, Equatable {
        enum Kind {
            case success
            case joined
            case left
        }

        let id = UUID()
        let kind: Kind
        let text: String
        let avatar: RoomAvatar?
    }

    final class ViewModel: ObservableObject {
        @Published private(set) var roomState = RoomState.idle
        @Published private(set) var relayState = RelayState.none {
            didSet { relayState == .preparing ? startRelayTimeout() : relayTimeoutTask?.cancel() }
        }
        /// Why the relay failed (`room:relay.errorCode` or the reply code), shown for support.
        @Published private(set) var relayErrorCode: String?
        @Published private(set) var snapshot: RoomSnapshot?
        /// The host lost the network and is getting the room (and the picture) back.
        @Published private(set) var isReconnecting = false
        /// Swapping to a new relay generation mid-playback: a short reload, not a pause.
        @Published private(set) var isSwitchingStream = false
        @Published private(set) var banner: Banner?
        @Published private(set) var isCodeCopied = false
        @Published var sheet: Sheet?
        @Published var isLeaveDialogPresented = false
        @Published var isPlaybackFailedPresented = false
        @Published var toast: String?
        /// Which of `playlist.channels` is playing; only more than one entry when the Xtream
        /// category this channel came from was passed in (see `IPTVPlaylist.xtreamPlayback`).
        @Published private(set) var selectedIndex: Int

        let playlist: IPTVPlaylist
        let player = PlayerController()
        let identity = RoomIdentity.current
        let speedOptions: [(title: String, rate: Float)] = [
            ("0.5 x", 0.5), ("0.75 x", 0.75), ("1.0 x", 1.0), ("1.25 x", 1.25), ("1.5 x", 1.5), ("2.0 x", 2.0)
        ]

        private let onBack: () -> Void
        private var room: RoomService?
        private var roomCancellable: AnyCancellable?
        private var offlineCancellable: AnyCancellable?
        private var hasStarted = false
        private var leavesScreen = false
        private var loadedStream: RoomStream?
        private var loadedGeneration: Int?
        private var streamTask: Task<Void, Never>?
        private var resolveTask: Task<Void, Never>?
        private var resolvedURL: URL?
        private var refreshTask: Task<Void, Never>?
        private var bannerTask: Task<Void, Never>?
        private var copyTask: Task<Void, Never>?
        private var relayTimeoutTask: Task<Void, Never>?
        /// The server gives up on a source after 45 s; past this the relay is considered stuck.
        private let relayTimeout: UInt64 = 60

        init(playlist: IPTVPlaylist, onBack: @escaping () -> Void) {
            self.playlist = playlist
            self.onBack = onBack
            // `playlist.id` is the id of the channel that was tapped (see `xtreamPlayback`); find
            // it among `channels` so playback starts on the right one when there is more than one.
            selectedIndex = playlist.channels.firstIndex(where: { $0.id == playlist.id }) ?? 0

            player.onUserPlay = { [weak self] _ in self?.sendControl(.play) }
            player.onUserPause = { [weak self] _ in self?.sendControl(.pause) }
            player.onLoadFailed = { [weak self] _ in
                guard let self, self.isReconnecting != true else { return }
                // Switching channels mid-room would desync the relay; let the room's own
                // "relay failed" UI handle that case instead.
                guard self.roomState == .idle else {
                    self.toast = "playlist_player_error_message".localized(
                        fallback: "This channel cannot be played. Please try another channel."
                    )
                    return
                }
                self.isPlaybackFailedPresented = true
            }
        }

        deinit {
            streamTask?.cancel()
            refreshTask?.cancel()
            resolveTask?.cancel()
            room?.endRoom()
        }

        // MARK: - Channel

        var channels: [IPTVChannel] { playlist.channels }
        var currentChannel: IPTVChannel? {
            channels.indices.contains(selectedIndex) ? channels[selectedIndex] : nil
        }
        var hasNextChannel: Bool { channels.count > 1 }
        private var loadID: String { currentChannel?.id ?? playlist.id }

        // MARK: - Texts

        var title: String { playlist.name }
        var videoTitle: String { currentChannel?.title ?? playlist.name }
        var loadingText: String {
            if isReconnecting { return "watch_together_reconnecting".localized(fallback: "Connection lost. Reconnecting…") }
            return relayState == .preparing
                ? "watch_together_preparing".localized(fallback: "Preparing the video…")
                : "playlist_player_loading".localized(fallback: "Loading channel...")
        }

        var premiumAction: (() -> Void)? {
            IAPHelper.shared().isSubscribed() ? nil : { AppNavigator.presentPaywall() }
        }

        // MARK: - Room state for the screen

        var isHosting: Bool { roomState == .hosting }
        var roomCode: String { snapshot?.code ?? "" }
        var watcherCount: Int { snapshot?.participantCount ?? 1 }
        var hasViewers: Bool { (snapshot?.viewerCount ?? 0) > 0 }

        /// Everybody in the room, host first. Until the server sends names and avatars the viewers
        /// are numbered placeholders.
        var participants: [RoomParticipant] {
            if let list = snapshot?.participants, !list.isEmpty { return list }
            let guest = "watch_together_guest".localized(fallback: "Guest %d")
            var result = [RoomParticipant(
                id: "host", name: identity.name, avatar: identity.avatar.key, role: .host, joinedAt: nil
            )]
            for index in 0..<(snapshot?.viewerCount ?? 0) {
                result.append(RoomParticipant(
                    id: "viewer-\(index)",
                    name: String(format: guest, index + 1),
                    avatar: RoomAvatar.at(index + 1).key,
                    role: .viewer,
                    joinedAt: nil
                ))
            }
            return result
        }

        /// What the player controls show while a live relay drives the clock.
        var roomPlayback: PlayVideoControlsOverlay.RoomPlayback? {
            guard isHosting, relayState == .ready, let duration = snapshot?.duration, duration > 0 else { return nil }
            return .init(
                position: { [weak self] in self?.currentMoviePosition() ?? 0 },
                duration: duration,
                onSkip: { [weak self] seconds in
                    guard let self else { return }
                    seek(to: currentMoviePosition() + seconds)
                },
                onSeek: { [weak self] fraction in
                    guard let self else { return }
                    seek(to: fraction * duration)
                }
            )
        }

        // MARK: - Lifecycle

        func onAppear() {
            player.isActive = true
            guard !hasStarted else { return }
            hasStarted = true
            player.setAspect(.cropToFill)
            if let url = sourceURL, XtreamStreamResolver.isSeriesInfoURL(url) {
                resolveSeries(url)
            } else {
                player.load(url: sourceURL, id: loadID)
            }
        }

        func onDisappear() {
            player.isActive = false
            if player.isFullscreen {
                player.setFullscreen(false)
            }
            closeRoom()
            player.cleanup()
        }

        // MARK: - Actions

        func didTapBack() {
            if isHosting {
                leavesScreen = true
                isLeaveDialogPresented = true
            } else {
                InterstitialGuard.perform(onBack)
            }
        }

        func showAudioOutput() {
            sheet = .audioOutput
        }

        /// The system picker cannot open over the sheet, so it waits for the sheet to go.
        func connectAudioOutput() {
            sheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { AirPlayPicker.present() }
        }

        func showSpeedOptions() {
            sheet = .speed
        }

        func selectSpeed(_ rate: Float) {
            sheet = nil
            player.setPlaybackRate(rate)
        }

        func dismissSheet() {
            sheet = nil
        }

        func askLeave() {
            leavesScreen = false
            isLeaveDialogPresented = true
        }

        func cancelLeave() {
            isLeaveDialogPresented = false
            leavesScreen = false
        }

        /// Ends the room (the host leaving closes it for everybody) and goes back to the original source.
        func confirmLeave() {
            isLeaveDialogPresented = false
            let shouldLeaveScreen = leavesScreen
            leavesScreen = false
            if shouldLeaveScreen {
                closeRoom()
                InterstitialGuard.perform(onBack)
            } else {
                let position = currentMoviePosition()
                let wasPlaying = player.isPlaying
                closeRoom()
                player.load(url: sourceURL, id: loadID, startAt: position, autoplay: wasPlaying)
            }
        }

        func showInvite() {
            sheet = .invite
        }

        func showPeople() {
            sheet = .people
        }

        func dismissBanner() {
            bannerTask?.cancel()
            banner = nil
        }

        func dismissPlaybackFailedDialog() {
            isPlaybackFailedPresented = false
        }

        /// "Next Channel" on the playback-failure dialog: wraps to the first channel after the last.
        func selectNextChannel() {
            isPlaybackFailedPresented = false
            guard channels.count > 1 else { return }
            selectedIndex = (selectedIndex + 1) % channels.count
            resolvedURL = nil
            if let url = sourceURL, XtreamStreamResolver.isSeriesInfoURL(url) {
                resolveSeries(url)
            } else {
                player.load(url: sourceURL, id: loadID)
            }
        }

        func copyCode() {
            guard isHosting else { return }
            UIPasteboard.general.string = roomCode
            isCodeCopied = true
            copyTask?.cancel()
            copyTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                self?.isCodeCopied = false
            }
        }

        func shareCode() {
            guard isHosting else { return }
            let format = "watch_together_share_message".localized(fallback: "Join my room on IPTV Together Hub with code %@")
            UIApplication.shared.share(items: [String(format: format, roomCode)])
        }

        func retryRelay() {
            guard let room, relayState == .failed else { return }
            relayState = .preparing
            relayErrorCode = nil
            Task { @MainActor [weak self] in
                do {
                    try await room.retryRelay()
                } catch {
                    self?.relayState = .failed
                    self?.relayErrorCode = (error as? RoomError)?.code
                    Logger.e("Retry relay failed", error)
                }
            }
        }

        func createRoom() {
            guard roomState == .idle, let channel = currentChannel, let source = sourceURL,
                  !XtreamStreamResolver.isSeriesInfoURL(source) else { return }
            roomState = .creating

            Task { @MainActor [weak self] in
                guard let self else { return }
                // The length of a stream is only known once the player has loaded it.
                guard let duration = await resolveDuration() else {
                    roomState = .idle
                    toast = "watch_together_create_failed".localized(fallback: "Couldn't create the room. Please try again.")
                    return
                }
                startRoom(channel: channel, source: source, duration: duration)
            }
        }

        private func startRoom(channel: IPTVChannel, source: URL, duration: Double) {
            let room = RoomService()
            room.onRelay = { [weak self] in self?.handleRelay($0) }
            room.onParticipant = { [weak self] in self?.handleParticipant($0) }
            room.onHostResumed = { [weak self] in self?.hostResumed() }
            room.onHostResumeFailed = { [weak self] error in self?.hostResumeFailed(error) }
            self.room = room
            offlineCancellable = room.$isHostOffline
                .removeDuplicates()
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] offline in
                    if offline { self?.isReconnecting = true }
                }
            roomCancellable = room.$snapshot
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.handleSnapshot($0) }

            Task { @MainActor [weak self] in
                do {
                    _ = try await room.createRoom(mediaId: "m3u-\(channel.id)", duration: duration, identity: identity)
                    guard let self, self.room === room else { return }
                    roomState = .hosting
                    relayState = .preparing
                    showBanner(.success, text: "watch_together_room_created".localized(fallback: "Room created successfully"))
                    try await room.startRelay(sourceURL: source.absoluteString, format: Self.format(of: source.absoluteString))
                } catch {
                    guard let self, self.room === room else { return }
                    if roomState == .hosting {
                        relayState = .failed
                        relayErrorCode = (error as? RoomError)?.code
                    } else {
                        closeRoom()
                        let message = "watch_together_create_failed".localized(fallback: "Couldn't create the room. Please try again.")
                        toast = (error as? RoomError).map { "\(message) (\($0.code))" } ?? message
                    }
                    Logger.e("Room setup failed", error)
                }
            }
        }

        // MARK: - Server events

        private func handleSnapshot(_ snapshot: RoomSnapshot?) {
            guard let snapshot, room != nil else { return }
            let previous = self.snapshot
            self.snapshot = snapshot

            guard snapshot.isActive else {
                let finished = snapshot.reason == "movie_finished"
                closeRoom()
                toast = finished
                    ? "watch_together_finished".localized(fallback: "The movie has finished.")
                    : "watch_together_ended".localized(fallback: "The room has ended.")
                return
            }

            // Diff participants for a named banner; fall back to a generic one from the viewer
            // count only if a snapshot ever lacks the list.
            if let previous {
                if let previousList = previous.participants, let currentList = snapshot.participants {
                    let previousIDs = Set(previousList.map(\.id))
                    let currentIDs = Set(currentList.map(\.id))
                    if let joined = currentList.first(where: { !previousIDs.contains($0.id) }) {
                        showBanner(.joined, text: Self.joinedText(joined.name), avatar: RoomAvatar(key: joined.avatar))
                    } else if let left = previousList.first(where: { !currentIDs.contains($0.id) }) {
                        showBanner(.left, text: Self.leftText(left.name), avatar: RoomAvatar(key: left.avatar))
                    }
                } else if previous.viewerCount != snapshot.viewerCount {
                    let someone = "watch_together_someone".localized(fallback: "Someone")
                    if snapshot.viewerCount > previous.viewerCount {
                        showBanner(.joined, text: Self.joinedText(someone), avatar: RoomAvatar.at(snapshot.viewerCount))
                    } else {
                        showBanner(.left, text: Self.leftText(someone), avatar: RoomAvatar.at(previous.viewerCount))
                    }
                }
            }
        }

        // MARK: - Reconnect

        /// The host is back with a new socket: the old relay link is void, so take a new one and
        /// go to where the room is now (it kept playing meanwhile).
        private func hostResumed() {
            guard let room else { return }
            showBanner(.success, text: "watch_together_reconnected".localized(fallback: "Reconnected"))
            guard relayState == .ready else {
                isReconnecting = false
                return
            }
            streamTask?.cancel()
            streamTask = Task { @MainActor [weak self] in
                do {
                    let (stream, url) = try await room.stream()
                    guard let self, !Task.isCancelled, room === self.room else { return }
                    loadedStream = stream
                    loadedGeneration = stream.generation
                    player.load(url: url, id: "room-\(stream.generation)-c", autoplay: snapshot?.isPlaying ?? false)
                    scheduleRefresh(of: stream)
                    await resume(at: roomDate(for: stream))
                    isReconnecting = false
                } catch {
                    guard let self else { return }
                    isReconnecting = false
                    loadedGeneration = nil
                    relayState = .failed
                    relayErrorCode = (error as? RoomError)?.code ?? "STREAM_DECODE"
                    Logger.e("Room stream after reconnect failed", error)
                }
            }
        }

        private func hostResumeFailed(_ error: RoomError) {
            closeRoom()
            toast = "watch_together_ended".localized(fallback: "The room has ended.")
        }

        /// Wall-clock time of the room's current position inside this generation.
        private func roomDate(for stream: RoomStream) -> Date? {
            guard let snapshot, let origin = stream.timelineOriginUnixMs else { return nil }
            var position = snapshot.position
            if snapshot.isPlaying, snapshot.buffering != true {
                position += max(Date().timeIntervalSince1970 * 1000 - snapshot.serverTime, 0) / 1000
            }
            return Date(timeIntervalSince1970: (origin + (position - stream.basePosition) * 1000) / 1000)
        }

        private func handleParticipant(_ event: RoomParticipantEvent) {
            guard event.code == snapshot?.code else { return }
            let avatar = RoomAvatar(key: event.participant.avatar)
            switch event.type {
            case .joined: showBanner(.joined, text: Self.joinedText(event.participant.name), avatar: avatar)
            case .left: showBanner(.left, text: Self.leftText(event.participant.name), avatar: avatar)
            }
        }

        private func handleRelay(_ event: RoomRelayEvent) {
            guard event.code == snapshot?.code else { return }
            switch event.status {
            case .starting:
                relayState = .preparing
            case .ready, .paused:
                // The relay reports itself paused while it swaps generations; the host decides
                // whether playback runs, so keep playing if that is what it was already doing.
                loadStream(generation: event.generation, autoplay: event.status == .ready || player.isPlaying)
            case .error:
                relayState = .failed
                relayErrorCode = event.errorCode
            case .stopped:
                break
            }
        }

        // MARK: - Relay playback

        /// Takes the link of the relay generation. A new generation (after a seek, or play after the
        /// source paused) replaces the playlist; the old one answers 409.
        private func loadStream(generation: Int, autoplay: Bool) {
            guard let room, loadedGeneration != generation else { return }
            loadedGeneration = generation
            streamTask?.cancel()
            streamTask = Task { @MainActor [weak self] in
                do {
                    let (stream, url) = try await room.stream()
                    guard let self, !Task.isCancelled, room === self.room else { return }
                    // Carry the current frame over: a new generation (e.g. a viewer joining)
                    // otherwise restarts the host from zero.
                    let resumeDate = relayState == .ready ? player.currentDate : nil
                    isSwitchingStream = resumeDate != nil
                    defer { isSwitchingStream = false }
                    loadedStream = stream
                    relayState = .ready
                    player.load(url: url, id: "room-\(stream.generation)", autoplay: autoplay)
                    // Autoplay starts the player directly, bypassing `onUserPlay`: tell the room
                    // explicitly, or its stale "not playing" snapshot pauses us again seconds later.
                    if autoplay { sendControl(.play) }
                    await resume(at: resumeDate)
                    scheduleRefresh(of: stream)
                } catch let error as RoomError where error.code == "RELAY_STARTING" || error.code == "RELAY_NOT_STARTED" {
                    // `room:relay` will tell when the source is ready.
                    self?.loadedGeneration = nil
                } catch {
                    guard let self else { return }
                    loadedGeneration = nil
                    relayState = .failed
                    relayErrorCode = (error as? RoomError)?.code ?? "STREAM_DECODE"
                    Logger.e("Room stream failed", error)
                }
            }
        }

        /// The link expires; ask for a new one a minute before and carry on from the same frame.
        private func scheduleRefresh(of stream: RoomStream) {
            refreshTask?.cancel()
            let delay = max(stream.expiresAt / 1000 - Date().timeIntervalSince1970 - 60, 5)
            refreshTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let self, !Task.isCancelled, let room, loadedStream?.generation == stream.generation else { return }
                guard let (fresh, url) = try? await room.stream(), fresh.generation == stream.generation else { return }
                let date = player.currentDate
                let wasPlaying = player.isPlaying
                loadedStream = fresh
                player.load(url: url, id: "room-\(fresh.generation)-r", autoplay: wasPlaying)
                await resume(at: date)
                scheduleRefresh(of: fresh)
            }
        }

        /// Seeks the new item to the wall-clock time the old one was at, once it is ready.
        @MainActor
        private func resume(at date: Date?) async {
            guard let date else { return }
            for _ in 0..<40 {
                try? await Task.sleep(nanoseconds: 250_000_000)
                if let item = player.player?.currentItem, item.status == .readyToPlay {
                    _ = await item.seek(to: date)
                    return
                }
            }
        }

        // MARK: - Host controls

        private func sendControl(_ action: RoomService.Action) {
            guard isHosting, relayState == .ready else { return }
            room?.send(action, position: currentMoviePosition())
        }

        private func seek(to position: Double) {
            guard isHosting, let duration = snapshot?.duration else { return }
            room?.send(.seek, position: min(max(position, 0), duration))
        }

        /// Position in the movie. The relay playlist is a sliding window, so its own clock is only
        /// meaningful through the program date and the generation's origin.
        private func currentMoviePosition() -> Double {
            let duration = snapshot?.duration ?? .greatestFiniteMagnitude
            guard let stream = loadedStream else { return min(player.currentSeconds, duration) }
            var position = stream.basePosition + player.currentSeconds
            if let date = player.currentDate, let origin = stream.timelineOriginUnixMs {
                position = stream.basePosition + (date.timeIntervalSince1970 * 1000 - origin) / 1000
            }
            return min(max(position, 0), duration)
        }

        // MARK: - Private

        private func startRelayTimeout() {
            relayTimeoutTask?.cancel()
            relayTimeoutTask = Task { @MainActor [weak self, relayTimeout] in
                try? await Task.sleep(nanoseconds: relayTimeout * 1_000_000_000)
                guard let self, !Task.isCancelled, relayState == .preparing else { return }
                RoomLog.note("relay not ready after \(relayTimeout)s")
                relayState = .failed
                relayErrorCode = "RELAY_TIMEOUT"
            }
        }

        private func closeRoom() {
            relayTimeoutTask?.cancel()
            streamTask?.cancel()
            refreshTask?.cancel()
            roomCancellable = nil
            offlineCancellable = nil
            isReconnecting = false
            room?.endRoom()
            room = nil
            snapshot = nil
            loadedStream = nil
            loadedGeneration = nil
            relayState = .none
            relayErrorCode = nil
            roomState = .idle
            dismissBanner()
        }

        private func showBanner(_ kind: Banner.Kind, text: String, avatar: RoomAvatar? = nil) {
            bannerTask?.cancel()
            banner = Banner(kind: kind, text: text, avatar: avatar)
            bannerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                self?.banner = nil
            }
        }

        /// What actually plays: the episode behind an Xtream series link once it is known.
        private var sourceURL: URL? {
            resolvedURL ?? URL(string: currentChannel?.url ?? "")
        }

        /// An Xtream series is listed with an info link; the first episode is the stream to play and relay.
        private func resolveSeries(_ infoURL: URL) {
            resolveTask?.cancel()
            resolveTask = Task { @MainActor [weak self] in
                do {
                    let episodeURL = try await XtreamStreamResolver.firstEpisodeURL(from: infoURL)
                    guard !Task.isCancelled, let self else { return }
                    resolvedURL = episodeURL
                    player.load(url: episodeURL, id: loadID)
                } catch {
                    guard !Task.isCancelled, let self else { return }
                    toast = XtreamStreamResolver.message(for: error)
                    player.load(url: nil, id: loadID)
                }
            }
        }

        /// The known length, else waits for the player to load it (up to 8 s).
        private func resolveDuration() async -> Double? {
            if let known = videoDuration { return known }
            for _ in 0..<16 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if Task.isCancelled { return nil }
                if let known = videoDuration { return known }
                // A live stream reports an indefinite length once it has loaded.
                if player.player?.currentItem?.duration.isIndefinite == true { return RoomSnapshot.liveDuration }
            }
            return nil
        }

        var isLiveRoom: Bool { snapshot?.isLive == true }

        private var videoDuration: Double? {
            if let seconds = currentChannel?.duration, seconds > 0 { return Double(seconds) }
            let loaded = player.player?.currentItem?.duration.seconds ?? 0
            return loaded.isFinite && loaded > 0 ? loaded : nil
        }

        private static func format(of url: String) -> RoomService.SourceFormat {
            URL(string: url)?.path.lowercased().contains(".m3u8") == true ? .hls : .file
        }

        private static func joinedText(_ name: String) -> String {
            String(format: "watch_together_joined".localized(fallback: "%@ joined the room"), name)
        }

        private static func leftText(_ name: String) -> String {
            String(format: "watch_together_left".localized(fallback: "%@ left the room"), name)
        }
    }
}
