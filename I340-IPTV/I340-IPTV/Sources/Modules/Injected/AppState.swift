//
//  AppState.swift
//  I340_IPTV
//
//  Created by Toan Nguyen on 19/11/24.
//

import Combine
import Foundation
import SwiftUI

struct AppState: Equatable {
    var path = FlowPath()
    var route = AppRoute.splash(isFromLanguageSetting: false)
    var system = System()
}

extension AppState {
    struct System: Equatable {
        var isActive: Bool = false
        var keyboardHeight: CGFloat = 0
    }
}

#if DEBUG
    extension AppState {
        static var preview: AppState {
            var state = AppState()
            state.system.isActive = true
            return state
        }
    }
#endif
