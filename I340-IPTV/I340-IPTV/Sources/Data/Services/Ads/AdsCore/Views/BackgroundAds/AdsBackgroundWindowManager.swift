//
//  AdsBackgroundWindowManager.swift
//
//  Created by Sơn Lê on 25/11/25.
//  Copyright © 2025 Foxcode Corps. All rights reserved.
//

import UIKit

/// Top-level window to present Ads as a full-screen view controller
public final class AdsBackgroundWindowManager {
    public static let shared = AdsBackgroundWindowManager()
    
    public var isVisible: Bool {
        return backgroundWindow != nil && backgroundWindow?.isHidden == false
    }

    private var backgroundWindow: UIWindow?
    weak var hostVC: UIViewController?

    public func show(rootVC: UIViewController, isComeback: Bool = false, showAd: (() -> ())? = nil) {
        guard backgroundWindow == nil else { return }

        AdsManager.shared.setPresentingFullScreenAd(true)
        AdsManager.shared.armSkipAppear(for: rootVC, count: 1) /// Skip reload native after show full screen ad
        
        // Pick the current foreground scene (for multi-window safety)
        let win = UIWindow(frame: UIScreen.main.bounds)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            win.windowScene = scene
        }

        win.windowLevel = .alert
        win.backgroundColor = .clear

        let host = BackgroundShowAdsVC(isComeback: isComeback)
        win.rootViewController = host
        win.makeKeyAndVisible()

        self.backgroundWindow = win
        self.hostVC = host
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showAd?()
        }
    }

    public func hide() {
        tearDownWindow()
        AdsManager.shared.setPresentingFullScreenAd(false)
    }

    private func tearDownWindow() {
        backgroundWindow?.isHidden = true
        backgroundWindow = nil
        hostVC = nil
    }
}
