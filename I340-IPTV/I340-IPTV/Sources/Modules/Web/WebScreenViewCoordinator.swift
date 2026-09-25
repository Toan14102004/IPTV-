//
//  WebScreenViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension WebScreenView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case loadFailed
        }

        var alert: Alert?
    }
}
