//
//  NoConnectionViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension NoConnectionView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            /// "Try again" was tapped while the device is still offline.
            case stillOffline
        }

        var alert: Alert?
    }
}
