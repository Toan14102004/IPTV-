//
//  PlaylistAddMenuOption.swift
//  I340_IPTV
//

import Foundation

enum PlaylistAddMenuOption: CaseIterable {
    case importPlaylistURL
    case importXtreamCodeAPI
    case importFromDevice
    case playSingleStream
    
    var titleKey: String {
        switch self {
        case .importPlaylistURL:
            return "playlist_menu_import_url"
        case .importXtreamCodeAPI:
            return "playlist_menu_import_xtream_api"
        case .importFromDevice:
            return "playlist_menu_import_device"
        case .playSingleStream:
            return "playlist_menu_play_single_stream"
        }
    }
    
    var fallbackTitle: String {
        switch self {
        case .importPlaylistURL:
            return "Import Playlist URL"
        case .importXtreamCodeAPI:
            return "Import from Xtream Code API"
        case .importFromDevice:
            return "Import from Device"
        case .playSingleStream:
            return "Play Single Stream"
        }
    }
    
    var icon: ImageAsset {
        switch self {
        case .importPlaylistURL: Asset.Icon.icPlaylistMenuImportUrl
        case .importXtreamCodeAPI: Asset.Icon.icPlaylistMenuXtreamApi
        case .importFromDevice: Asset.Icon.icPlaylistMenuImportDevice
        case .playSingleStream: Asset.Icon.icPlaylistMenuSingleStream
        }
    }

    var relatedPlaylistOption: PlaylistOption? {
        switch self {
        case .importPlaylistURL:
            return .playlistURL
        case .importFromDevice:
            return .file
        case .playSingleStream:
            return .stream
        case .importXtreamCodeAPI:
            return nil
        }
    }
}
