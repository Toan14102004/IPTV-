//
//  ImportPlaylistTab.swift
//  I340_IPTV
//

import Foundation

enum ImportPlaylistTab: CaseIterable, Hashable, Codable {
    case playlist
    case file
    case stream

    var titleKey: String {
        switch self {
        case .playlist: "import_tab_playlist"
        case .file: "import_tab_file"
        case .stream: "import_tab_stream"
        }
    }

    var fallbackTitle: String {
        switch self {
        case .playlist: "Playlist"
        case .file: "File"
        case .stream: "Stream"
        }
    }

    var image: ImageAsset {
        switch self {
        case .playlist: Asset.Image.imgImportM3u
        case .file: Asset.Image.imgImportFile
        case .stream: Asset.Image.imgImportStream
        }
    }
}
