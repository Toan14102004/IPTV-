//
//  WatchLimitPaywallCoordinator.swift
//  I340-IPTV
//
//  Created by Codex on 07/07/2026.
//

import UIKit

protocol WatchLimitLockable: AnyObject {
    func pauseForWatchLimitPaywall()
    func resumeAfterWatchLimitPurchase()
    func leavePlaybackAfterWatchLimitDismiss()
}

final class WatchLimitPaywallCoordinator: NSObject {
    private static var watchStartedAt: Date?
    
    private weak var lockable: WatchLimitLockable?
    private let watchLimit: TimeInterval
    private var limitWorkItem: DispatchWorkItem?
    private var isPresentingPaywall = false
    private var didUnlockPlayback = false
    private var didReceivePurchaseSuccess = false
    
    init(
        lockable: WatchLimitLockable,
        watchLimit: TimeInterval = 60
    ) {
        self.lockable = lockable
        self.watchLimit = watchLimit
        super.init()
        
        IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
            guard isPurchased else { return }
            DispatchQueue.main.async {
                self?.handleSubscriptionSucceeded()
            }
        }
    }
    
    func startWatchingIfNeeded() {
        guard !IAPHelper.shared().isSubscribed(), !isPresentingPaywall else { return }
        guard Self.watchStartedAt == nil else { return }
        
        let watchedDuration = UserDefaultManager.shared().watchLimitWatchedDuration
        let remainingDuration = max(watchLimit - watchedDuration, 0)
        if remainingDuration <= 0 {
            presentPaywall()
            return
        }
        
        Self.watchStartedAt = Date()
        schedulePaywall(after: remainingDuration)
    }
    
    func pauseWatching() {
        guard let watchStartedAt = Self.watchStartedAt else { return }
        
        UserDefaultManager.shared().watchLimitWatchedDuration += Date().timeIntervalSince(watchStartedAt)
        Self.watchStartedAt = nil
        limitWorkItem?.cancel()
        limitWorkItem = nil
    }
    
    func reset() {
        pauseWatching()
        limitWorkItem?.cancel()
        limitWorkItem = nil
        isPresentingPaywall = false
        didReceivePurchaseSuccess = false
    }
    
    private func schedulePaywall(after duration: TimeInterval) {
        limitWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.presentPaywall()
        }
        limitWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    
    private func presentPaywall() {
        guard !IAPHelper.shared().isSubscribed() else {
            resetWatchLimitAfterPurchase()
            return
        }
        
        guard let lockable else { return }
        guard Self.isAnotherScreenPresented == false else {
            schedulePaywall(after: 1)
            return
        }
        
        pauseWatching()
        // Persist the exhausted allowance before presenting the paywall so
        // relaunching the app cannot reset the free viewing period.
        let userDefaults = UserDefaultManager.shared()
        userDefaults.watchLimitWatchedDuration = max(userDefaults.watchLimitWatchedDuration, watchLimit)
        isPresentingPaywall = true
        didUnlockPlayback = false
        didReceivePurchaseSuccess = false
        lockable.pauseForWatchLimitPaywall()
        
        Task { @MainActor [weak self] in
            AppNavigator.presentPaywall(delegate: self)
        }
    }
}

extension WatchLimitPaywallCoordinator {
    /// A cover, sheet or alert is on screen over the window root (for instance the paywall).
    static var isAnotherScreenPresented: Bool {
        UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController?.presentedViewController != nil
    }
}

extension WatchLimitPaywallCoordinator: PaywallDelegate {
    func onDismiss(isPurchased: Bool) {
        if isPurchased || didReceivePurchaseSuccess || IAPHelper.shared().isSubscribed() {
            unlockPlaybackAfterPurchase()
        } else {
            isPresentingPaywall = false
            lockable?.leavePlaybackAfterWatchLimitDismiss()
        }
    }
}

private extension WatchLimitPaywallCoordinator {
    func handleSubscriptionSucceeded() {
        didReceivePurchaseSuccess = true
        guard isPresentingPaywall, Self.isAnotherScreenPresented == false else { return }
        
        unlockPlaybackAfterPurchase()
    }
    
    func unlockPlaybackAfterPurchase() {
        guard !didUnlockPlayback else { return }
        didUnlockPlayback = true
        resetWatchLimitAfterPurchase()
        
        lockable?.resumeAfterWatchLimitPurchase()
    }
    
    func resetWatchLimitAfterPurchase() {
        UserDefaultManager.shared().watchLimitWatchedDuration = 0
        Self.watchStartedAt = nil
        limitWorkItem?.cancel()
        limitWorkItem = nil
        isPresentingPaywall = false
        didReceivePurchaseSuccess = false
    }
}
