//
//  PlaylistChannelViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PlaylistChannelView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case deleteChannel(IPTVChannel)
        }

        var alert: Alert?
        /// Channel whose "more" menu is open.
        var actionMenuID: String?
        /// Channel being renamed.
        var rename: IPTVChannel?
    }
}
