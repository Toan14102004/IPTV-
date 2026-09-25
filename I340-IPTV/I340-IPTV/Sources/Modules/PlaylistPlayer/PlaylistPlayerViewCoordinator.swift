//
//  PlaylistPlayerViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PlaylistPlayerView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            /// The selected channel could not be played.
            case playbackFailed
        }

        var alert: Alert?
    }
}
