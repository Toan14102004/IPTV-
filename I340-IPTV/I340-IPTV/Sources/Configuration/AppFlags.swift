//
//  AppFlags.swift
//  I340_IPTV
//

import Foundation

/// Build-time switches. Every ad surface reads `Configs.Advertisement.canRequestAndShowAds`,
/// which follows `adsEnabled`, so shipping a version without ads means flipping one constant.
enum AppFlags {
    /// Ships every ad surface: native, interstitial, rewarded and app-open.
    private static let adsShipped = true

    static var adsEnabled: Bool { adsShipped }
}
