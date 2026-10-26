//
//  AppNavigator.swift
//  I340_IPTV
//

import SwiftUI
import UIKit

/// Short-hands for the screens that can be opened from anywhere, on top of the root `FlowStack`.
/// Screens with their own navigation needs use `@Navigation var navigator` directly.
@MainActor
enum AppNavigator {
    typealias Navigation = RootView.Coordinator.Navigation
    typealias FullScreen = RootView.Coordinator.FullScreen

    private static var navigator: FlowPathNavigator? { FlowNavigatorHolder.shared.navigator }

    static func push(_ screen: Navigation) {
        navigator?.push(screen)
    }

    static func present(_ screen: FullScreen) {
        navigator?.presentCover(screen)
    }

    static func back() {
        navigator?.goBack()
    }

    /// The paywall (not shown to subscribers). `delegate` hears how it was closed.
    static func presentPaywall(delegate: PaywallDelegate? = nil) {
        guard !IAPHelper.shared().isSubscribed() else { return }
        PaywallCenter.shared.delegate = delegate
        present(.paywall)
    }
}

/// Carries the result of the paywall to whoever asked for it (the watch-limit logic).
@MainActor
final class PaywallCenter {
    static let shared = PaywallCenter()

    weak var delegate: PaywallDelegate?

    func finish(isPurchased: Bool) {
        let receiver = delegate
        delegate = nil
        receiver?.onDismiss(isPurchased: isPurchased)
    }
}
