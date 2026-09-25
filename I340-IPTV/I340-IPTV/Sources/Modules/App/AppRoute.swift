//
//  AppRoute.swift
//  I340_IPTV
//

import Foundation

/// What the window root is showing. Screens opened from Main are pushed on the root `FlowStack`
/// (see `RootView.Coordinator.Navigation`).
enum AppRoute: Equatable {
    case splash(isFromLanguageSetting: Bool)
    case language
    case onboard
    case main
}
