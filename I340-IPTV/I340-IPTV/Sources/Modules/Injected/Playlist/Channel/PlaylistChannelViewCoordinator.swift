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
        var actionMenuID: String?
        var rename: IPTVChannel?
    }
}
