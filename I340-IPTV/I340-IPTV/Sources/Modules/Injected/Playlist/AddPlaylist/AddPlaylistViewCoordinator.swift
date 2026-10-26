//
//  AddPlaylistViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension AddPlaylistView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case message(String)
            case xtreamLoading
            case xtreamFailed
        }

        var alert: Alert?
    }
}
