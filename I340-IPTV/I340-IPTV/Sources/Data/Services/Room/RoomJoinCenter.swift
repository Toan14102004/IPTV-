//
//  RoomJoinCenter.swift
//  I340_IPTV
//

import Foundation

/// A room is joined before its screen opens (a wrong code stays on the Room tab), and the
/// connection that joined must be the one the viewer screen keeps. Routes can only carry values,
/// so the joined service waits here for the screen to take it.
@MainActor
final class RoomJoinCenter {
    static let shared = RoomJoinCenter()

    private static let lastCodeKey = "room.lastJoinedCode"

    private var joined: [String: RoomService] = [:]

    var lastCode: String? {
        get { UserDefaults.standard.string(forKey: Self.lastCodeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.lastCodeKey) }
    }

    func hold(_ service: RoomService, for code: String) {
        joined[code] = service
    }

    func take(_ code: String) -> RoomService? {
        joined.removeValue(forKey: code)
    }
}
