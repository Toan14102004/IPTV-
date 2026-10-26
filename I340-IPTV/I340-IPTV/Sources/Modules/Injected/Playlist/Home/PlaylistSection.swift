//
//  PlaylistSection.swift
//  I340_IPTV
//

import Foundation

enum PlaylistSection: Hashable, Codable {
    case playlists
    case videos

    /// Xtream profiles live in the Xtream tab, so they are in neither group. A single stream is
    /// one video (one URL, one channel) same as a device file, so it joins Videos too.
    func contains(_ playlist: IPTVPlaylist) -> Bool {
        switch self {
        case .playlists: playlist.source != .file && playlist.source != .stream && playlist.source != .xtream
        case .videos: playlist.source == .file || playlist.source == .stream
        }
    }

    var titleKey: String {
        switch self {
        case .playlists: "playlist_section_playlist"
        case .videos: "playlist_section_videos"
        }
    }

    var fallbackTitle: String {
        switch self {
        case .playlists: "PLAYLIST"
        case .videos: "VIDEOS"
        }
    }

    var screenTitleKey: String {
        switch self {
        case .playlists: "main_playlist"
        case .videos: "playlist_videos_title"
        }
    }

    var icon: ImageAsset {
        switch self {
        case .playlists: Asset.Icon.icPlaylistSectionPlaylist
        case .videos: Asset.Icon.icPlaylistSectionVideos
        }
    }
}

extension IPTVPlaylist {
    var channelCountText: String {
        let appLanguage = UserDefaultManager.shared().appLanguage
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: appLanguage.isEmpty ? Locale.current.identifier : appLanguage)
        let count = formatter.string(from: NSNumber(value: channels.count)) ?? "\(channels.count)"
        let format = "playlist_channels_count".localized(fallback: "%d channels")
            .replacingOccurrences(of: "%d", with: "%@")
        return String(format: format, count)
    }
}

/// Playlists marked with the heart, kept in `UserDefaults`.
enum PlaylistFavorites {
    static func toggle(_ id: String) -> Set<String> {
        var ids = Set(UserDefaultManager.shared().favoritePlaylistIDs)
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        UserDefaultManager.shared().favoritePlaylistIDs = Array(ids)
        return ids
    }

    static func remove(_ id: String) -> Set<String> {
        var ids = Set(UserDefaultManager.shared().favoritePlaylistIDs)
        ids.remove(id)
        UserDefaultManager.shared().favoritePlaylistIDs = Array(ids)
        return ids
    }
}

extension IPTVPlaylist {
    /// Duration of the video ("56:32"), or a placeholder when the file has none.
    var videoSubtitle: String {
        guard let seconds = channels.first?.duration, seconds > 0 else { return "--:--" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%02d:%02d", minutes, secs)
    }
}

extension IPTVPlaylist {
    /// A device file is a single video and plays right away.
    var opensPlayerDirectly: Bool { source == .file || source == .stream }
}
