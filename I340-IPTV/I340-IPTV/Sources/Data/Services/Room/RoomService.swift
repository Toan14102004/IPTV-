//
//  RoomService.swift
//  I340_IPTV
//

import Combine
import Foundation
import Network
import SocketIO

/// A watch-together room over Socket.IO (namespace `/rooms`), as its host or as a viewer.
///
/// The connection that creates a room is its host; the room closes when that connection
/// leaves or drops, so one service lives as long as the screen that hosts the room. The host
/// plays the movie from the server's relay like everybody else: `startRelay` hands the source
/// to the server, `stream` returns the temporary HLS link.
final class RoomService: ObservableObject {
    enum Action: String {
        case play
        case pause
        case seek
    }

    enum SourceFormat: String {
        case hls
        case file
    }

    @Published private(set) var snapshot: RoomSnapshot?
    /// The host's connection dropped and the service is getting it back (the server keeps the room
    /// for about 30 s); controls are held until then.
    @Published private(set) var isHostOffline = false

    /// The host is back and the old relay link is void: ask for a new one.
    var onHostResumed: (() -> Void)?
    /// The host could not take the room back (it ended, or the token was refused).
    var onHostResumeFailed: ((RoomError) -> Void)?

    var onRelay: ((RoomRelayEvent) -> Void)?
    var onParticipant: ((RoomParticipantEvent) -> Void)?

    private let origin: URL
    private let manager: SocketManager
    private let socket: SocketIOClient
    private let ackTimeout: Double = 5

    /// Controls must reach the server one at a time with the latest revision; while one is in
    /// flight only the newest pending one is kept.
    private var isSendingControl = false
    private var pendingControl: (action: Action, position: Double)?

    /// Proof that this device created the room, kept only in memory and never logged or shared.
    private var hostResume: (code: String, token: String)?
    private var resumeTask: Task<Void, Never>?
    /// The socket can stay "connected" for ~45 s after the network is gone; the device's own
    /// network state tells sooner, so the host reconnects as soon as it is back.
    private var pathMonitor: NWPathMonitor?

    init(serverURL: String = Configs.Network.roomsServerURL) {
        let url = URL(string: serverURL)!
        origin = url
        manager = SocketManager(
            socketURL: url,
            config: [.log(false), .compress, .path("/socket.io/"), .reconnects(false)]
        )
        socket = manager.socket(forNamespace: "/rooms")

        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            RoomLog.note("socket disconnected \(data)")
            DispatchQueue.main.async { self?.connectionDropped() }
        }
        socket.on(clientEvent: .reconnectAttempt) { data, _ in RoomLog.note("socket reconnect attempt \(data)") }
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async { self?.connectionRestored() }
        }
        socket.on(clientEvent: .error) { data, _ in RoomLog.note("socket error \(data)") }
        socket.on(clientEvent: .statusChange) { data, _ in RoomLog.note("socket status \(data)") }

        socket.on("room:state") { [weak self] data, _ in
            RoomLog.received("room:state", data.first ?? "")
            guard let reply = data.first, let snapshot = try? Self.decode(RoomSnapshot.self, fromReply: reply) else { return }
            DispatchQueue.main.async { self?.apply(snapshot) }
        }
        socket.on("room:relay") { [weak self] data, _ in
            RoomLog.received("room:relay", data.first ?? "")
            guard let reply = data.first, let event = try? Self.decode(RoomRelayEvent.self, fromReply: reply) else { return }
            DispatchQueue.main.async { self?.onRelay?(event) }
        }
        socket.on("room:participant") { [weak self] data, _ in
            RoomLog.received("room:participant", data.first ?? "")
            guard let reply = data.first, let event = try? Self.decode(RoomParticipantEvent.self, fromReply: reply) else { return }
            DispatchQueue.main.async { self?.onParticipant?(event) }
        }
    }

    deinit {
        pathMonitor?.cancel()
        socket.disconnect()
    }

    // MARK: - Host

    func createRoom(mediaId: String, duration: Double, identity: RoomIdentity) async throws -> RoomSnapshot {
        try await connect()
        let base: [String: Any] = ["mediaId": mediaId, "duration": duration]
        let reply: Any
        do {
            reply = try await requestRaw("room:create", base.merging([
                "name": identity.name,
                "avatar": identity.avatar.key
            ]) { $1 })
        } catch let error as RoomError where error.code == "VALIDATION_ERROR" {
            // A server that does not know `name` / `avatar` yet rejects them as unknown fields.
            reply = try await requestRaw("room:create", base)
        }
        let snapshot = try Self.decode(RoomSnapshot.self, fromReply: reply)
        // Saved before anything plays: it is the only way back if the host loses the network.
        if let created = try? Self.decode(HostCreated.self, fromReply: reply), let token = created.hostResumeToken {
            hostResume = (snapshot.code, token)
            RoomLog.note("host resume token saved")
            watchNetwork()
            manager.reconnects = true
            manager.reconnectWait = 1
            manager.reconnectWaitMax = 4
        }
        apply(snapshot)
        AnalyticsService.shared.log(.custom("room_create"))
        return snapshot
    }

    // MARK: - Viewer

    func joinRoom(code: String, identity: RoomIdentity) async throws -> RoomSnapshot {
        RoomLog.note("join \(code): start")
        do {
            try await connect()
            let snapshot: RoomSnapshot
            do {
                snapshot = try await request("room:join", [
                    "code": code,
                    "name": identity.name,
                    "avatar": identity.avatar.key
                ])
            } catch let error as RoomError where error.code == "VALIDATION_ERROR" {
                RoomLog.note("join \(code): name/avatar rejected, retrying with the code only")
                snapshot = try await request("room:join", ["code": code])
            }
            apply(snapshot)
            AnalyticsService.shared.log(.custom("room_join"))
            RoomLog.note("join \(code): ok status=\(snapshot.status) revision=\(snapshot.revision)")
            return snapshot
        } catch {
            RoomLog.note("join \(code): failed \((error as? RoomError)?.code ?? "\(error)")")
            throw error
        }
    }

    /// Leaves the room as a viewer and closes the connection.
    func leaveRoom() {
        forgetHostResume()
        if let code = snapshot?.code, snapshot?.isActive == true {
            RoomLog.sent("room:leave", ["code": code])
            socket.emitWithAck("room:leave", ["code": code]).timingOut(after: ackTimeout) { [weak self] _ in
                self?.socket.disconnect()
            }
        } else {
            socket.disconnect()
        }
    }

    // MARK: - Relay

    /// Hands the movie source to the server. The URL carries the host's credentials: it is only
    /// sent here and never logged.
    func startRelay(sourceURL: String, format: SourceFormat) async throws {
        guard let code = snapshot?.code else { throw RoomError.notConnected }
        let _: RelayAck = try await request("room:relay:start", [
            "code": code,
            "sourceUrl": sourceURL,
            "format": format.rawValue
        ])
    }

    func retryRelay() async throws {
        guard let code = snapshot?.code else { throw RoomError.notConnected }
        let _: RelayAck = try await request("room:relay:retry", ["code": code])
    }

    /// Link of the current relay generation, already joined with the API origin.
    func stream() async throws -> (stream: RoomStream, url: URL) {
        guard let code = snapshot?.code else { throw RoomError.notConnected }
        let stream: RoomStream = try await request("room:stream", ["code": code])
        guard let url = URL(string: stream.path, relativeTo: origin)?.absoluteURL else { throw RoomError.invalidReply }
        if let state = stream.state { apply(state) }
        return (stream, url)
    }

    func send(_ action: Action, position: Double) {
        guard let snapshot, snapshot.isActive, !isHostOffline else { return }
        let clamped = min(max(position, 0), snapshot.duration)
        if isSendingControl {
            pendingControl = (action, clamped)
            return
        }
        isSendingControl = true
        Task { @MainActor [weak self] in
            await self?.performControl(action, position: clamped)
        }
    }

    /// Ends the room for everyone and closes the connection.
    func endRoom() {
        forgetHostResume()
        if let code = snapshot?.code, snapshot?.isActive == true {
            RoomLog.sent("room:end", ["code": code])
            socket.emitWithAck("room:end", ["code": code]).timingOut(after: ackTimeout) { [weak self] _ in
                self?.socket.disconnect()
            }
        } else {
            socket.disconnect()
        }
    }

    // MARK: - Private

    private struct HostCreated: Decodable {
        let hostResumeToken: String?
    }

    private func watchNetwork() {
        pathMonitor?.cancel()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.networkChanged(isOnline: path.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "room.network"))
        pathMonitor = monitor
    }

    private func networkChanged(isOnline: Bool) {
        guard hostResume != nil else { return }
        guard isOnline else {
            if !isHostOffline { RoomLog.note("network lost") }
            isHostOffline = true
            return
        }
        guard isHostOffline else { return }
        // The old socket may be a dead one that still looks connected: replace it.
        RoomLog.note("network back, reconnecting the socket")
        resumeTask?.cancel()
        socket.disconnect()
        socket.connect()
    }

    private func forgetHostResume() {
        pathMonitor?.cancel()
        pathMonitor = nil
        hostResume = nil
        resumeTask?.cancel()
        manager.reconnects = false
        isHostOffline = false
    }

    private func connectionDropped() {
        guard hostResume != nil else { return }
        RoomLog.note("host connection lost, waiting for the socket to reconnect")
        isHostOffline = true
    }

    private func connectionRestored() {
        guard hostResume != nil, isHostOffline else { return }
        resumeTask?.cancel()
        resumeTask = Task { @MainActor [weak self] in await self?.resumeHost() }
    }

    /// `room:join` with the token on the new socket gives the host its room back. The server may
    /// still see the old socket for a moment (`HOST_ALREADY_CONNECTED`): wait and ask again.
    @MainActor
    private func resumeHost() async {
        let started = Date()
        while !Task.isCancelled, let resume = hostResume, socket.status == .connected {
            do {
                let reply = try await requestRaw("room:join", ["code": resume.code, "hostResumeToken": resume.token])
                let restored = try Self.decode(RoomSnapshot.self, fromReply: reply)
                apply(restored)
                isHostOffline = false
                RoomLog.note("host resumed room \(restored.code)")
                onHostResumed?()
                return
            } catch let error as RoomError where error.code == "HOST_ALREADY_CONNECTED" || error.code == RoomError.timeout.code {
                guard Date().timeIntervalSince(started) < 60 else {
                    failResume(error)
                    return
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
                failResume((error as? RoomError) ?? RoomError.invalidReply)
                return
            }
        }
    }

    private func failResume(_ error: RoomError) {
        RoomLog.note("host could not resume: \(error.code)")
        forgetHostResume()
        onHostResumeFailed?(error)
    }

    private struct RelayAck: Decodable {
        let code: String
        let status: String
    }

    @MainActor
    private func performControl(_ action: Action, position: Double) async {
        for attempt in 0..<2 {
            guard let current = snapshot, current.isActive else { break }
            do {
                let updated: RoomSnapshot = try await request("room:control", [
                    "code": current.code,
                    "action": action.rawValue,
                    "position": position,
                    "sentAt": Int(Date().timeIntervalSince1970 * 1000),
                    "expectedRevision": current.revision
                ])
                apply(updated)
                break
            } catch let error as RoomError where error.code == "STALE_ROOM_STATE" && attempt == 0 {
                guard let fresh: RoomSnapshot = try? await request("room:state", ["code": current.code]) else { break }
                apply(fresh)
            } catch {
                Logger.e("Room control failed", error)
                break
            }
        }

        if let next = pendingControl {
            pendingControl = nil
            await performControl(next.action, position: next.position)
        } else {
            isSendingControl = false
        }
    }

    private func apply(_ snapshot: RoomSnapshot) {
        guard snapshot.isNewer(than: self.snapshot) else { return }
        self.snapshot = snapshot
    }

    private func connect() async throws {
        guard socket.status != .connected else { return }
        RoomLog.note("socket status before connect: \(socket.status)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var didResume = false
            func finish(_ result: Result<Void, Error>) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(with: result)
            }
            socket.once(clientEvent: .connect) { _, _ in
                RoomLog.note("connected to /rooms")
                finish(.success(()))
            }
            socket.once(clientEvent: .error) { data, _ in
                RoomLog.note("connect error \(data)")
                finish(.failure(RoomError.notConnected))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if !didResume { RoomLog.note("connect timed out after 10s (socket status \(self.socket.status))") }
                finish(.failure(RoomError.notConnected))
            }
            RoomLog.note("connecting to \(origin.absoluteString)/rooms")
            socket.connect()
        }
    }

    private func request<T: Decodable>(_ event: String, _ body: [String: Any]) async throws -> T {
        try Self.decode(T.self, fromReply: try await requestRaw(event, body))
    }

    private func requestRaw(_ event: String, _ body: [String: Any]) async throws -> Any {
        RoomLog.sent(event, body)
        let reply: Any = try await withCheckedThrowingContinuation { continuation in
            socket.emitWithAck(event, body).timingOut(after: ackTimeout) { items in
                RoomLog.received("ack \(event)", items.first ?? "")
                if let first = items.first as? String, first == SocketAckStatus.noAck.rawValue {
                    RoomLog.note("\(event): no answer within \(Int(self.ackTimeout))s")
                    continuation.resume(throwing: RoomError.timeout)
                } else if let first = items.first {
                    continuation.resume(returning: first)
                } else {
                    continuation.resume(throwing: RoomError.invalidReply)
                }
            }
        }
        return reply
    }

    /// `{ success: true, data }` or `{ success: false, code, message }`.
    private static func decode<T: Decodable>(_ type: T.Type, fromReply reply: Any) throws -> T {
        guard let dictionary = reply as? [String: Any] else { throw RoomError.invalidReply }
        guard dictionary["success"] as? Bool == true, let data = dictionary["data"] else {
            throw RoomError(
                code: dictionary["code"] as? String ?? "UNKNOWN",
                message: dictionary["message"] as? String ?? "Room request failed."
            )
        }
        let json = try JSONSerialization.data(withJSONObject: data)
        do {
            return try JSONDecoder().decode(T.self, from: json)
        } catch {
            RoomLog.note("decode \(T.self) failed: \(error)")
            throw error
        }
    }
}
