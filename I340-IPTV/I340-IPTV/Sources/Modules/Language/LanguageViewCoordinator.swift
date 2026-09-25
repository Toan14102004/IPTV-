//
//  LanguageViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension LanguageView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            /// Changing the language after onboarding needs an app restart.
            case restartRequired
        }

        var alert: Alert?
    }
}
