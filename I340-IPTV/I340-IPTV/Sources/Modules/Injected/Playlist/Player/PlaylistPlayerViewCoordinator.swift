//
//  PlaylistPlayerViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PlaylistPlayerView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case playbackFailed
        }

        var alert: Alert?
    }
}
