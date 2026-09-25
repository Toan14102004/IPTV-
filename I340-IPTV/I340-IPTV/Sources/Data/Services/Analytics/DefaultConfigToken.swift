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

enum RemoteConfigDefault {
    static let NavigateReinstall: NSString = ""
    static let ABBilling: NSNumber = .init(value: false)
    static let isShowWeekProduct: NSNumber = .init(value: false)
    static let isShowMonthProduct: NSNumber = .init(value: false)
    static let isShowYearProduct: NSNumber = .init(value: true)
    static let isShowAdLanguage: NSNumber = .init(value: true)
    static let isShowAdTheme: NSNumber = .init(value: true)
    static let isShowAdIntro: NSNumber = .init(value: true)
    static let isShowAdInterstitial: NSNumber = .init(value: true)
    static let delayShowIntervalInterstitial: NSNumber = 30
    static let isShowOpenAdFromBackground: NSNumber = .init(value: true)
    static let isShowOpenAdLanguageAndIntro: NSNumber = .init(value: false)
    static let abTesting2F: NSNumber = .init(value: true)
    static let abTestingMiniPackage: NSNumber = .init(value: true)
    static let isShowNativeLanguage2F: NSNumber = .init(value: true)
    static let isShowNativeIntro2F: NSNumber = .init(value: true)
    static let isShowInterFistLaunchApp: NSNumber = .init(value: true)
    static let geminiAIKey: NSString = "AIzaSyCd0chxLf5ae1SBswMtmWytWqKlfBBujaI"
    static let geminiAIModel: NSString = "gemini-2.5-flash"
    static let geminiAIPrompt: NSString = """
You are an advanced AI capable of analyzing image and recognizing dogs.
I will provide you with an image. Your task is to:
1. Detect and identify any dogs based on the provided image.
2. If dogs are detected, provide their details including breed, approximate age, and notable features.
3. Additionally, generate a list of 3 related dog breeds that might have similar characteristics or historical relevance.
4. If the image are not related to dogs, return an empty list.
Ensure to only provide responses related to dogs and avoid returning any non-dog related data.
"""
    
}
