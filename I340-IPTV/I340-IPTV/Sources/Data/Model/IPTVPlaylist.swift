import Foundation

enum IPTVPlaylistSource: String, Codable {
    case playlistURL
    case file
    case stream
    case clipboard
    case xtream
    case unknown
}

struct IPTVPlaylist: Codable, Hashable {
    var id: String
    var name: String
    var url: String
    var source: IPTVPlaylistSource
    var channels: [IPTVChannel]
    var createdAt: Date
    var updatedAt: Date

    /// Identity only: a playlist can hold thousands of channels and is used as a navigation value.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(
        id: String = UUID().uuidString,
        name: String = "",
        url: String = "",
        source: IPTVPlaylistSource = .playlistURL,
        channels: [IPTVChannel] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.source = source
        self.channels = channels
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var chanels: [IPTVChannel] {
        get { channels }
        set { channels = newValue }
    }
}

typealias IPTVList = IPTVPlaylist

struct XtreamProfilePayload {
    let serverURL: String
    let username: String
    let password: String
    let avatarName: String
    
    static func encode(
        serverURL: String,
        username: String,
        password: String,
        avatarName: String = "avatar_xtream_2"
    ) -> String {
        var components = URLComponents()
        components.scheme = "i340-xtream"
        components.host = "profile"
        components.queryItems = [
            URLQueryItem(name: "server", value: serverURL),
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "avatar", value: avatarName)
        ]
        return components.string ?? serverURL
    }
    
    static func decode(from value: String) -> XtreamProfilePayload {
        guard
            let components = URLComponents(string: value),
            components.scheme == "i340-xtream"
        else {
            return XtreamProfilePayload(serverURL: value, username: "", password: "", avatarName: "avatar_xtream_2")
        }
        
        let items = components.queryItems ?? []
        return XtreamProfilePayload(
            serverURL: items.first(where: { $0.name == "server" })?.value ?? "",
            username: items.first(where: { $0.name == "username" })?.value ?? "",
            password: items.first(where: { $0.name == "password" })?.value ?? "",
            avatarName: items.first(where: { $0.name == "avatar" })?.value ?? "avatar_xtream_2"
        )
    }
}

extension IPTVPlaylist: Identifiable {}
