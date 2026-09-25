//
//  PlaylistOption.swift
//  I340_IPTV
//

import Foundation

enum PlaylistOption: CaseIterable {
    case playlistURL
    case file
    case stream
    case favorite
    
    var titleKey: String {
        switch self {
        case .playlistURL:
            return "main_playlist_url"
        case .file:
            return "main_file"
        case .stream:
            return "main_stream"
        case .favorite:
            return "main_favorite"
        }
    }
    
    var fallbackTitle: String {
        switch self {
        case .playlistURL:
            return "Playlist URL"
        case .file:
            return "File"
        case .stream:
            return "Stream"
        case .favorite:
            return "Favorite"
        }
    }
    
    var iconName: String {
        switch self {
        case .playlistURL:
            return "ic_main_chip_link"
        case .file:
            return "ic_main_chip_file"
        case .stream:
            return "ic_main_chip_stream"
        case .favorite:
            return "ic_main_chip_favorite"
        }
    }
    
    var minimumWidth: CGFloat {
        switch self {
        case .playlistURL:
            return 132
        case .file:
            return 78
        case .stream:
            return 105
        case .favorite:
            return 118
        }
    }
}
