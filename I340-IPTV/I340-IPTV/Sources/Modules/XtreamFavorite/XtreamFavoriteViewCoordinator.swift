//
//  XtreamFavoriteViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension XtreamFavoriteView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case clearAll
        }

        var alert: Alert?
    }
}
