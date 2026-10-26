//
//  RoomModels.swift
//  I340_IPTV
//

import Foundation

/// State of a watch-together room as sent by the server. `position` is the position at
/// `serverTime`, not at `updatedAt`.
struct RoomSnapshot: Decodable, Equatable {
    let code: String
    let mediaId: String
    let duration: Double
    let status: String
    let playback: String
    let position: Double
    let serverTime: Double
    let revision: Int
    let viewerCount: Int
    let participantCount: Int
    let reason: String?
    /// Whether the relay is still preparing the first segments (the position clock is paused).
    let buffering: Bool?
    /// Names and avatars; only present once the backend sends them.
    let participants: [RoomParticipant]?
    /// Whether the host is connected; `false` while the room waits for the host to come back.
    let hostConnected: Bool?
    /// Unix milliseconds by which the host must be back, or `nil` when nobody is waiting.
    let hostReconnectDeadline: Double?

    /// A live channel has no length, so its room runs on this stand-in: the position follows the
    /// clock and the controls show LIVE instead of a progress bar.
    static let liveDuration: Double = 86_400
    var isLive: Bool { duration >= Self.liveDuration }

    var isActive: Bool { status == "active" }
    var isPlaying: Bool { playback == "playing" }

    /// Older revisions, or the same revision with an older `serverTime`, are stale.
    func isNewer(than other: RoomSnapshot?) -> Bool {
        guard let other, other.code == code else { return true }
        if revision != other.revision { return revision > other.revision }
        return serverTime >= other.serverTime
    }
}

struct RoomParticipant: Decodable, Equatable, Identifiable {
    enum Role: String, Decodable {
        case host
        case viewer
    }

    let id: String
    let name: String
    let avatar: String
    let role: Role
    let joinedAt: Double?

    private enum CodingKeys: String, CodingKey { case id, name, avatar, role, joinedAt }

    init(id: String, name: String, avatar: String, role: Role, joinedAt: Double?) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.role = role
        self.joinedAt = joinedAt
    }

    /// The backend sends `avatar: null` until it stores avatars, so a missing value decodes as "".
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar) ?? ""
        role = try c.decode(Role.self, forKey: .role)
        joinedAt = try c.decodeIfPresent(Double.self, forKey: .joinedAt)
    }
}

/// `room:participant`: somebody joined or left.
struct RoomParticipantEvent: Decodable, Equatable {
    enum Kind: String, Decodable {
        case joined
        case left
    }

    struct Person: Decodable, Equatable {
        let id: String
        let name: String
        let avatar: String

        private enum CodingKeys: String, CodingKey { case id, name, avatar }

        init(id: String, name: String, avatar: String) {
            self.id = id
            self.name = name
            self.avatar = avatar
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
            avatar = try c.decodeIfPresent(String.self, forKey: .avatar) ?? ""
        }
    }

    let code: String
    let type: Kind
    let participant: Person
}

/// `room:relay`: how far the server is with the temporary HLS stream of the room.
struct RoomRelayEvent: Decodable, Equatable {
    enum Status: String, Decodable {
        case starting
        case ready
        case paused
        case error
        case stopped
    }

    let code: String
    let status: Status
    let generation: Int
    let basePosition: Double
    let timelineOriginUnixMs: Double?
    let errorCode: String?

    var isPlayable: Bool { status == .ready || status == .paused }
}

/// Reply of `room:stream`: the HLS playlist of one generation and how to map its clock to the movie.
struct RoomStream: Decodable, Equatable {
    let code: String
    let status: String
    let generation: Int
    let basePosition: Double
    let timelineOriginUnixMs: Double?
    let path: String
    let expiresAt: Double
    let state: RoomSnapshot?
}

struct RoomError: LocalizedError, Equatable {
    let code: String
    let message: String

    static let timeout = RoomError(code: "TIMEOUT", message: "The room server did not answer.")
    static let notConnected = RoomError(code: "NOT_CONNECTED", message: "Could not connect to the room server.")
    static let invalidReply = RoomError(code: "INVALID_REPLY", message: "Unexpected reply from the room server.")

    var errorDescription: String? { message }
}
