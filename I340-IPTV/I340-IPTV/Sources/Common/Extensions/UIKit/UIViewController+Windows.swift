//
//  UIViewController+Windows.swift
//  I340_IPTV
//

import UIKit

extension UIViewController {
    /// The controller the user is looking at: follows presented controllers, navigation
    /// and tab containers.
    func fx_topMost() -> UIViewController {
        if let presented = presentedViewController {
            return presented.fx_topMost()
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.fx_topMost()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.fx_topMost()
        }
        return self
    }
}

/// Window helpers for the ads logic (see `NativeAdController`).
extension UIViewController {
    /// Identifies the ads debug window (`accessibilityIdentifier == "AdsDebugWindow"` or a name
    /// containing "Debug").
    func isDebugWindow(_ window: UIWindow) -> Bool {
        if window.accessibilityIdentifier == "AdsDebugWindow" { return true }

        let windowName = String(describing: type(of: window))
        if windowName.contains("AdsDebug") || windowName.contains("Debug") { return true }

        if let root = window.rootViewController {
            let rootName = String(describing: type(of: root))
            if rootName.contains("AdsDebug") || rootName.contains("Debug") { return true }
        }
        return false
    }

    /// System / helper windows (keyboard, text effects, status bar, no root) must not count as
    /// covering the app.
    func isIgnorableSystemWindow(_ window: UIWindow) -> Bool {
        let name = String(describing: type(of: window))
        if name.contains("UIRemoteKeyboard") { return true }
        if name.contains("UITextEffects") { return true }
        if name.contains("UIStatusBar") { return true }
        return window.rootViewController == nil
    }

    /// Front-most window excluding the debug window and system / helper windows.
    func frontNonDebugWindow(in scene: UIWindowScene?) -> UIWindow? {
        let windows = scene?.windows ?? UIApplication.shared.windows

        let candidates = windows.filter { window in
            !window.isHidden
                && window.alpha > 0.01
                && !isDebugWindow(window)
                && !isIgnorableSystemWindow(window)
        }

        // windowLevel desc -> key window first -> later in the array first.
        return candidates.sorted {
            if $0.windowLevel != $1.windowLevel { return $0.windowLevel > $1.windowLevel }
            if $0.isKeyWindow != $1.isKeyWindow { return $0.isKeyWindow && !$1.isKeyWindow }
            let first = windows.firstIndex(of: $0) ?? 0
            let second = windows.firstIndex(of: $1) ?? 0
            return first > second
        }.first
    }
}
