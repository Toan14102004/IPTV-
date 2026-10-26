//
//  DefaultConfigToken.swift
//  I340_IPTV
//
//  Created by Foxcode on 11/9/24.
//

import Foundation

enum DefaultConfigToken {
    case adjustToken
    case adjustTokenPurchase
    case adjustTokenRestorePurchase
    case adjustTokenWeeklyPurchase
    case adjustTokenMonthlyPurchase
    case adjustTokenYearlyPurchase
    case adjustTokenOnetimePurchase
    case adjustTokenMiniPurchase
    
    case adjustTokenBannerAdImpressionEvent
    case adjustTokenInterAdImpressionEvent
    case adjustTokenNativeAdImpressionEvent
    case adjustTokenOpenAdImpressionEvent
    case adjustTokenBannerAdClick
    case adjustTokenInterAdClickKey
    case adjustTokenNativeAdClickKey
    case adjustTokenOpenAdClickKey
    case adjustTokenFirstOpen
    
    case adjustTokenAdRevenue
    case adjustTokenFreeTrialPredict

    case firebaseInAppFreeTrial

    var rawValue: String {
        switch self {
        case .adjustToken:
            return "ha6eamv6p69s"
        case .adjustTokenPurchase:
            return "9ji1uw"
        case .adjustTokenWeeklyPurchase:
            return "ci612s"
        case .adjustTokenMonthlyPurchase:
            return "2mon1q"
        case .adjustTokenYearlyPurchase:
            return "yfkdgf"
        case .adjustTokenRestorePurchase:
            return ""
        case .adjustTokenOnetimePurchase:
            return ""
        case .adjustTokenMiniPurchase:
            return ""
        case .adjustTokenBannerAdImpressionEvent:
            return ""
        case .adjustTokenInterAdImpressionEvent:
            return ""
        case .adjustTokenNativeAdImpressionEvent:
            return ""
        case .adjustTokenOpenAdImpressionEvent:
            return ""
        case .adjustTokenBannerAdClick:
            return ""
        case .adjustTokenInterAdClickKey:
            return ""
        case .adjustTokenNativeAdClickKey:
            return ""
        case .adjustTokenOpenAdClickKey:
            return ""
        case .adjustTokenFirstOpen:
            return ""
        case .adjustTokenAdRevenue:
            return ""

        case .adjustTokenFreeTrialPredict:
            return ""
        case .firebaseInAppFreeTrial:
            return "in_app_free_trial_predict"
        }
    }
}

