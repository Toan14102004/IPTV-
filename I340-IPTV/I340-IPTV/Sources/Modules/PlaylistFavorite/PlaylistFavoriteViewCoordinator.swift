//
//  PlaylistFavoriteViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PlaylistFavoriteView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case clearAll
            case remove(IPTVChannel)
        }

        var alert: Alert?
        /// Channel whose "more" menu is open.
        var actionMenuID: String?
    }
}
