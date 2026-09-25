//
//  SuppressAppOpenAdModifier.swift
//  I340_IPTV
//

import SwiftUI

extension View {
    /// No app-open ad while this view is on screen (the SwiftUI equivalent of the UIKit list of
    /// screens where `AdsManager` must not show one).
    func suppressesAppOpenAd() -> some View {
        modifier(SuppressAppOpenAdModifier())
    }
}

private struct SuppressAppOpenAdModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { AdsManager.shared.isAppOpenAdSuppressed = true }
            .onDisappear { AdsManager.shared.isAppOpenAdSuppressed = false }
    }
}
