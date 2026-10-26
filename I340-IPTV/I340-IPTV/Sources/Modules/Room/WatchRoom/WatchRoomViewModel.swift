//
//  WatchRoomViewModel.swift
//  I340_IPTV
//

import AVFoundation
import Combine
import Foundation
import UIKit

extension WatchRoomView {
    enum Status: Equatable {
        case joining
        /// The host has not handed over a playable source yet (not started, or the relay failed).
        case waitingHost(errorCode: String?)
        case preparing
        case watching
        case failed(errorCode: String)
        case ended(message: String)
    }

    final class ViewModel: ObservableObject {
        @Published private(set) var status = Status.joining {
            didSet { RoomLog.note("viewer status → \(status)") }
        }
        @Published private(set) var snapshot: RoomSnapshot?
        @Published private(set) var isCodeCopied = false
        @Published private(set) var banner: PlayVideoView.Banner?
        @Published var sheet: PlayVideoView.Sheet?
        @Published var isLeaveDialogPresented = false
        @Published var isEndedDialogPresented = false
        @Published var toast: String?

        let code: String
        let player = PlayerController()
        let identity = RoomIdentity.current

        private let onBack: () -> Void
        private var room: RoomService?
        private var roomCancellable: AnyCancellable?
        private var hasStarted = false
        private var loadedStream: RoomStream?
        private var loadedGeneration: Int?
        private var streamTask: Task<Void, Never>?
        private var refreshTask: Task<Void, Never>?
        private var copyTask: Task<Void, Never>?
        private var bannerTask: Task<Void, Never>?
        /// Server clock minus this device's clock, to count down to `hostReconnectDeadline`.
        private var serverClockOffset: Double = 0
        /// Drift past this many seconds from the room clock is corrected with a seek.
        private let maxDrift: Double = 3

        init(code: String, onBack: @escaping () -> Void) {
            self.code = code
            self.onBack = onBack

            player.onLoadFailed = { [weak self] _ in
                guard let self, status == .watching else { return }
                RoomLog.note("player could not open the relay link")
                loadedGeneration = nil
                status = .waitingHost(errorCode: "PLAYER_LOAD_FAILED")
            }
        }

        deinit {
            streamTask?.cancel()
            refreshTask?.cancel()
            room?.leaveRoom()
        }

        // MARK: - Texts

        var title: String {
            String(format: "room_title".localized(fallback: "Room %@"), code)
        }

        var watcherCount: Int { snapshot?.participantCount ?? 0 }
        var hasViewers: Bool { watcherCount > 1 }

        /// Everybody in the room. Until the server sends names, the host and this viewer are all that is known.
        var participants: [RoomParticipant] {
            if let list = snapshot?.participants, !list.isEmpty { return list }
            let host = RoomParticipant(
                id: "host", name: "watch_together_host".localized(fallback: "Host"),
                avatar: RoomAvatar.at(0).key, role: .host, joinedAt: nil
            )
            let me = RoomParticipant(
                id: "me", name: identity.name, avatar: identity.avatar.key, role: .viewer, joinedAt: nil
            )
            return [host, me]
        }

        /// The room's clock for the player controls; the viewer cannot change it.
        var roomPlayback: PlayVideoControlsOverlay.RoomPlayback? {
            guard status == .watching, let duration = snapshot?.duration, duration > 0 else { return nil }
            return .init(
                position: { [weak self] in
                    guard let self, let snapshot else { return 0 }
                    return roomPosition(snapshot)
                },
                duration: duration,
                onSkip: { _ in },
                onSeek: { _ in }
            )
        }

        /// The room is playing but this player has not started yet: the viewer shows a spinner
        /// instead of a stalled screen.
        var isRoomPlaying: Bool { snapshot?.isPlaying == true }

        var isBusy: Bool {
            switch status {
            case .joining, .preparing: true
            default: false
            }
        }

        var statusText: String? {
            switch status {
            case .joining:
                "room_joining".localized(fallback: "Joining the room…")
            case .waitingHost:
                "room_waiting_host".localized(fallback: "Waiting for the host to prepare the video…")
            case .preparing:
                "watch_together_preparing".localized(fallback: "Preparing the video…")
            case .watching:
                nil
            case let .failed(errorCode):
                "\("room_join_failed".localized(fallback: "Couldn't join the room.")) (\(errorCode))"
            case let .ended(message):
                message
            }
        }

        /// Seconds the room still waits for a host that lost the network, or `nil` when it is not waiting.
        func hostReconnectSecondsLeft(at date: Date) -> Int? {
            guard snapshot?.hostConnected == false, let deadline = snapshot?.hostReconnectDeadline else { return nil }
            let now = date.timeIntervalSince1970 * 1000 + serverClockOffset
            return max(Int(((deadline - now) / 1000).rounded(.up)), 0)
        }

        var endedMessage: String {
            if case let .ended(message) = status { return message }
            return "room_ended_message".localized(fallback: "The host has ended the room")
        }

        /// Shown under the status for testers and support.
        var errorCode: String? {
            if case let .waitingHost(errorCode) = status { return errorCode }
            return nil
        }

        // MARK: - Lifecycle

        func onAppear() {
            player.isActive = true
            guard !hasStarted else { return }
            hasStarted = true
            player.setAspect(.cropToFill)
            if let held = RoomJoinCenter.shared.take(code) {
                attach(held)
                showBanner(.joined, text: Self.joinedText("room_you".localized(fallback: "You")), avatar: identity.avatar)
                requestStream(autoplay: snapshot?.isPlaying ?? false)
            } else {
                join()
            }
        }

        func onDisappear() {
            player.isActive = false
            closeRoom()
            player.cleanup()
        }

        // MARK: - Actions

        func didTapBack() {
            isLeaveDialogPresented = true
        }

        func cancelLeave() {
            isLeaveDialogPresented = false
        }

        func confirmLeave() {
            isLeaveDialogPresented = false
            closeRoom()
            InterstitialGuard.perform(onBack)
        }

        func endedAcknowledged() {
            isEndedDialogPresented = false
            onBack()
        }

        func showInvite() {
            sheet = .invite
        }

        func showAudioOutput() {
            sheet = .audioOutput
        }

        func connectAudioOutput() {
            sheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { AirPlayPicker.present() }
        }

        func showPeople() {
            sheet = .people
        }

        func dismissBanner() {
            bannerTask?.cancel()
            banner = nil
        }

        func shareCode() {
            let format = "watch_together_share_message".localized(fallback: "Join my room on IPTV Together Hub with code %@")
            UIApplication.shared.share(items: [String(format: format, code)])
        }

        func copyCode() {
            UIPasteboard.general.string = code
            isCodeCopied = true
            copyTask?.cancel()
            copyTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                self?.isCodeCopied = false
            }
        }

        func retry() {
            guard case .failed = status else { return }
            closeRoom()
            join()
        }

        // MARK: - Join

        /// Fallback when the screen opens without a joined room (a restored route).
        private func join() {
            status = .joining
            let room = RoomService()
            attach(room)
            Task { @MainActor [weak self] in
                do {
                    _ = try await room.joinRoom(code: code, identity: identity)
                    guard let self, self.room === room else { return }
                    showBanner(.joined, text: Self.joinedText("room_you".localized(fallback: "You")), avatar: identity.avatar)
                    requestStream(autoplay: snapshot?.isPlaying ?? false)
                } catch {
                    guard let self, self.room === room else { return }
                    status = .failed(errorCode: (error as? RoomError)?.code ?? "UNKNOWN")
                    Logger.e("Join room failed", error)
                }
            }
        }

        private func attach(_ room: RoomService) {
            room.onRelay = { [weak self] in self?.handleRelay($0) }
            room.onParticipant = { [weak self] in self?.handleParticipant($0) }
            self.room = room
            roomCancellable = room.$snapshot
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.handleSnapshot($0) }
        }

        // MARK: - Server events

        private func handleSnapshot(_ snapshot: RoomSnapshot?) {
            guard let snapshot, room != nil else { return }
            let previous = self.snapshot
            self.snapshot = snapshot
            serverClockOffset = snapshot.serverTime - Date().timeIntervalSince1970 * 1000

            guard snapshot.isActive else {
                let finished = snapshot.reason == "movie_finished"
                RoomLog.note("room \(code) ended: status=\(snapshot.status) reason=\(snapshot.reason ?? "nil")")
                closeRoom()
                player.cleanup()
                status = .ended(message: finished
                    ? "watch_together_finished".localized(fallback: "The movie has finished.")
                    : snapshot.reason == "host_disconnected"
                    ? "watch_together_host_disconnected".localized(fallback: "The host lost connection, so the room has ended.")
                    : "room_ended_message".localized(fallback: "The host has ended the room"))
                isEndedDialogPresented = true
                return
            }

            // Somebody joining or leaving only changes the people list (same revision): correcting
            // the drift then would seek every viewer and make them reload.
            let playbackChanged = previous.map {
                $0.revision != snapshot.revision || $0.isPlaying != snapshot.isPlaying || $0.buffering != snapshot.buffering
            } ?? true
            if status == .watching, playbackChanged {
                sync(to: snapshot)
            }
        }

        private func handleRelay(_ event: RoomRelayEvent) {
            guard event.code == code else { return }
            switch event.status {
            case .starting:
                status = .preparing
            case .ready, .paused:
                guard loadedGeneration != event.generation else { return }
                requestStream(autoplay: event.status == .ready)
            case .error:
                status = .waitingHost(errorCode: event.errorCode)
            case .stopped:
                break
            }
        }

        // MARK: - Relay playback

        private func requestStream(autoplay: Bool) {
            guard let room else { return }
            streamTask?.cancel()
            streamTask = Task { @MainActor [weak self] in
                do {
                    let (stream, url) = try await room.stream()
                    guard let self, !Task.isCancelled, room === self.room else { return }
                    guard stream.status == "ready" || stream.status == "paused" else {
                        RoomLog.note("stream answered with status \(stream.status); waiting for room:relay")
                        status = .preparing
                        return
                    }
                    loadedStream = stream
                    loadedGeneration = stream.generation
                    status = .watching
                    player.load(url: url, id: "room-\(stream.generation)", autoplay: autoplay)
                    scheduleRefresh(of: stream)
                    await seekToRoomPosition()
                } catch let error as RoomError where error.code == "RELAY_STARTING" {
                    self?.status = .preparing
                } catch let error as RoomError where error.code == "RELAY_NOT_STARTED" || error.code == "RELAY_FAILED" {
                    self?.status = .waitingHost(errorCode: error.code == "RELAY_FAILED" ? error.code : nil)
                } catch {
                    guard let self, !Task.isCancelled else { return }
                    status = .waitingHost(errorCode: (error as? RoomError)?.code ?? "STREAM_DECODE")
                    Logger.e("Room stream failed", error)
                }
            }
        }

        private func scheduleRefresh(of stream: RoomStream) {
            refreshTask?.cancel()
            let delay = max(stream.expiresAt / 1000 - Date().timeIntervalSince1970 - 60, 5)
            refreshTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let self, !Task.isCancelled, let room, loadedStream?.generation == stream.generation else { return }
                guard let (fresh, url) = try? await room.stream(), fresh.generation == stream.generation else { return }
                loadedStream = fresh
                player.load(url: url, id: "room-\(fresh.generation)-r", autoplay: snapshot?.isPlaying ?? false)
                scheduleRefresh(of: fresh)
                await seekToRoomPosition()
            }
        }

        /// Play / pause follow the room; a drift past `maxDrift` seeks to where the room is.
        private func sync(to snapshot: RoomSnapshot) {
            guard snapshot.buffering != true, player.phase == .ready else { return }
            if snapshot.isPlaying != player.isPlaying {
                player.apply(position: player.currentSeconds, isPlaying: snapshot.isPlaying)
            }
            if let date = programDate(for: roomPosition(snapshot)), let current = player.currentDate,
               abs(current.timeIntervalSince(date)) > maxDrift {
                player.player?.currentItem?.seek(to: date, completionHandler: nil)
            }
        }

        /// Waits for the new item, then seeks it to the room's position and play state.
        @MainActor
        private func seekToRoomPosition() async {
            for _ in 0..<40 {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                guard let item = player.player?.currentItem, item.status == .readyToPlay else { continue }
                if let snapshot, let date = programDate(for: roomPosition(snapshot)) {
                    _ = await item.seek(to: date)
                    player.apply(position: player.currentSeconds, isPlaying: snapshot.isPlaying)
                }
                return
            }
        }

        /// Where the room is now: the snapshot position plus the time since, while playing.
        private func roomPosition(_ snapshot: RoomSnapshot) -> Double {
            guard snapshot.isPlaying, snapshot.buffering != true else { return snapshot.position }
            let elapsed = max(Date().timeIntervalSince1970 * 1000 - snapshot.serverTime, 0) / 1000
            return min(snapshot.position + elapsed, snapshot.duration)
        }

        /// Program date of a movie position in the loaded generation.
        private func programDate(for position: Double) -> Date? {
            guard let stream = loadedStream, let origin = stream.timelineOriginUnixMs else { return nil }
            return Date(timeIntervalSince1970: (origin + (position - stream.basePosition) * 1000) / 1000)
        }

        // MARK: - Private

        private func handleParticipant(_ event: RoomParticipantEvent) {
            guard event.code == code, event.participant.name != identity.name else { return }
            let avatar = RoomAvatar(key: event.participant.avatar)
            switch event.type {
            case .joined: showBanner(.joined, text: Self.joinedText(event.participant.name), avatar: avatar)
            case .left: showBanner(.left, text: Self.leftText(event.participant.name), avatar: avatar)
            }
        }

        private func showBanner(_ kind: PlayVideoView.Banner.Kind, text: String, avatar: RoomAvatar?) {
            bannerTask?.cancel()
            banner = PlayVideoView.Banner(kind: kind, text: text, avatar: avatar)
            bannerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                self?.banner = nil
            }
        }

        private static func joinedText(_ name: String) -> String {
            String(format: "watch_together_joined".localized(fallback: "%@ joined the room"), name)
        }

        private static func leftText(_ name: String) -> String {
            String(format: "watch_together_left".localized(fallback: "%@ left the room"), name)
        }

        private func closeRoom() {
            streamTask?.cancel()
            refreshTask?.cancel()
            roomCancellable = nil
            bannerTask?.cancel()
            room?.leaveRoom()
            room = nil
            loadedStream = nil
            loadedGeneration = nil
        }
    }
}
