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
    }
}
