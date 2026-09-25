//
//  XtreamViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension XtreamView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case disclaimer(XtreamProfileItem)
            case deleteProfile(XtreamProfileItem)
        }

        var alert: Alert?
        /// Profile whose "more" menu is open (id of the row it is anchored to).
        var actionMenuID: String?
        /// Profile being renamed.
        var rename: XtreamProfileItem?
    }
}
