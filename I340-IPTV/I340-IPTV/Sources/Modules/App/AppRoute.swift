//
//  AppRoute.swift
//  I340_IPTV
//

import Foundation

/// What the window root is showing. Screens opened from Content are pushed on the root `FlowStack`
/// (see `RootView.Coordinator.Navigation`).
enum AppRoute: Equatable {
    case splash(isFromLanguageSetting: Bool)
    case getStarted
    case language
    case onboard
    case content
}
