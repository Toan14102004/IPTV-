//
//  InterstitialGuard.swift
//  I340_IPTV
//

import UIKit

/// The interstitial that guards "back", settings and help taps.
enum InterstitialGuard {
    /// Runs `action` after the interstitial (immediately for subscribers or when no screen is on top).
    static func perform(_ action: @escaping () -> Void) {
        guard !IAPHelper.shared().isSubscribed(),
              let presenter = UIApplication.shared.topMostViewController else {
            action()
            return
        }
        AdsManager.shared.showInterAd(from: presenter) { _ in action() }
    }
}
