//
//  AddPlaylistTypes.swift
//  I340_IPTV
//

import Foundation

/// What the "add playlist" form is creating.
enum AddPlaylistMode: CaseIterable {
    case m3u
    case xtream
    case file

    var titleKey: String { "playlist_add_channel_title" }

    var primaryTitleKey: String {
        switch self {
        case .m3u, .xtream: "playlist_add_playlist_button"
        case .file: "playlist_add_select_file_button"
        }
    }

    var segmentTitleKey: String {
        switch self {
        case .m3u: "playlist_add_segment_m3u"
        case .xtream: "playlist_add_segment_xtream"
        case .file: "playlist_add_segment_file"
        }
    }
}

/// What the add screens hand back to the Playlist screen.
enum PlaylistAddChannelSubmission {
    case m3u(name: String, url: String)
    case file(name: String?, fileURL: URL)
    case stream(name: String?, url: String)
}
