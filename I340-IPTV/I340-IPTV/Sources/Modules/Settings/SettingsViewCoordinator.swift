//
//  SettingsViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension SettingsView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            case clearCache
        }

        var alert: Alert?
    }
}
