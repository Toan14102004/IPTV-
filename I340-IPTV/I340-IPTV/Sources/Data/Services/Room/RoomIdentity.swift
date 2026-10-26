//
//  RoomIdentity.swift
//  I340_IPTV
//

import Foundation

/// Panda avatars of the design; the key travels to the server as `avatar`.
enum RoomAvatar: String, CaseIterable {
    case pink
    case orange
    case green
    case magenta
    case blue
    case cyan
    case amber

    init(key: String) {
        let name = key.hasPrefix("panda_") ? String(key.dropFirst("panda_".count)) : key
        self = RoomAvatar(rawValue: name) ?? .pink
    }

    var key: String { "panda_" + rawValue }

    static func at(_ index: Int) -> RoomAvatar {
        allCases[((index % allCases.count) + allCases.count) % allCases.count]
    }

    var image: ImageAsset {
        switch self {
        case .pink: Asset.Image.imgAvatarPink
        case .orange: Asset.Image.imgAvatarOrange
        case .green: Asset.Image.imgAvatarGreen
        case .magenta: Asset.Image.imgAvatarMagenta
        case .blue: Asset.Image.imgAvatarBlue
        case .cyan: Asset.Image.imgAvatarCyan
        case .amber: Asset.Image.imgAvatarAmber
        }
    }
}

/// Who this device is in a room. There is no login, so a name and avatar are generated once.
struct RoomIdentity: Equatable {
    let name: String
    let avatar: RoomAvatar

    private static let nameKey = "room_identity_name"
    private static let avatarKey = "room_identity_avatar"

    static var current: RoomIdentity {
        let defaults = UserDefaults.standard
        if let name = defaults.string(forKey: nameKey), let avatar = defaults.string(forKey: avatarKey) {
            return RoomIdentity(name: name, avatar: RoomAvatar(key: avatar))
        }
        let identity = RoomIdentity(
            name: "User\(Int.random(in: 1000...9999))",
            avatar: RoomAvatar.allCases.randomElement() ?? .pink
        )
        defaults.set(identity.name, forKey: nameKey)
        defaults.set(identity.avatar.key, forKey: avatarKey)
        return identity
    }
}
