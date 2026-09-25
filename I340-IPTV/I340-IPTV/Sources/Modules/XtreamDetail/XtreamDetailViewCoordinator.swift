//
//  XtreamDetailViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension XtreamDetailView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case more
            case playbackSpeed
            case quality
            case aspectRatio
        }

        var alert: Alert?
    }
}
