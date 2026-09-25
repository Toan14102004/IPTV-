//
//  PlaylistViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PlaylistView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case cancelImport
            case importTimeout
            case deletePlaylist(IPTVPlaylist)
        }

        var alert: Alert?
        /// Playlist whose "more" menu is open (id of the row it is anchored to).
        var actionMenuID: String?
        /// Playlist being renamed.
        var rename: IPTVPlaylist?
    }
}
