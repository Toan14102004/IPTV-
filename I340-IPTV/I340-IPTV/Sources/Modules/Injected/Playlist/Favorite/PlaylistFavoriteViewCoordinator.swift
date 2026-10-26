//
//  PlaylistFavoriteViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PlaylistFavoriteView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case deletePlaylist(IPTVPlaylist)
            case deleteChannel(Item)
        }

        var alert: Alert?
        var actionMenuID: String?
        var rename: Item?
    }
}
