//
//  PaywallDelegate.swift
//  I340_IPTV
//

import Foundation

/// Told once the paywall has been closed (`isPurchased` is true after a purchase or a restore).
protocol PaywallDelegate: AnyObject {
    func onDismiss(isPurchased: Bool)
}
