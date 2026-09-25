//
//  RemoteKonfig.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import Foundation

/// RemoteKonfig provides direct access to remote config values
/// Only need to define once - key and default value together!
///
/// When RemoteKonfig.shared is initialized, all @RemoteKonfigProperty instances
/// will automatically register their defaults - no manual listing needed!
struct RemoteKonfig {
    
    // Create a single instance - when this is initialized, all property wrappers will run their init()
    static let shared = RemoteKonfig()
    
    // MARK: - Ad Visibility Configs
    
    @RemoteKonfigProperty(key: "i340_is_show_ad_language", default: true)
    var isShowAdLanguage: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_ad_theme", default: true)
    var isShowAdTheme: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_ad_intro", default: true)
    var isShowAdIntro: Bool

    @RemoteKonfigProperty(key: "i340_is_show_native_ads_full_screen_intro", default: true)
    var isShowNativeAdsFullScreenIntro: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_ad_interstitial", default: true)
    var isShowAdInterstitial: Bool
    
    @RemoteKonfigProperty(key: "i340_delay_show_interval_interstitial", default: 30)
    var delayShowIntervalInterstitial: Int
    
    @RemoteKonfigProperty(key: "i340_is_show_open_ad_from_background", default: true)
    var isShowOpenAdFromBackground: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_open_ad_language_and_intro", default: false)
    var isShowOpenAdLanguageAndIntro: Bool
    
    @RemoteKonfigProperty(key: "i340_ab_testing_2f_inter_open", default: true)
    var abTesting2F: Bool
    
    @RemoteKonfigProperty(key: "i340_ab_test_mini_package_inapp", default: true)
    var abTestingMiniPackage: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_native_language_2f", default: true)
    var isShowNativeLanguage2F: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_native_intro_2f", default: true)
    var isShowNativeIntro2F: Bool

    @RemoteKonfigProperty(key: "i340_is_show_native_intro_full_screen_2f", default: true)
    var isShowNativeIntroFullScreen2F: Bool

    @RemoteKonfigProperty(key: "i340_ab_native_language", default: true)
    var isAbNativeLanguage: Bool

    @RemoteKonfigProperty(key: "i340_ab_native_full_screen", default: true)
    var isAbNativeFullScr: Bool

    @RemoteKonfigProperty(key: "i340_ab_native_intro", default: true)
    var isAbNativeIntro: Bool
    
    @RemoteKonfigProperty(key: "isShowInterFistLaunchApp", default: true)
    var isShowInterFistLaunchApp: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_slide_ads", default: true)
    var isShowSlideAds: Bool
    
    @RemoteKonfigProperty(key: "i340_slide_ads_interval", default: 5)
    var slideAdsInterval: Int
    
    // MARK: - In-App Purchase Configs
    
    @RemoteKonfigProperty(key: "i340_ab_billing", default: false)
    var abBilling: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_week", default: false)
    var isShowWeekProduct: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_month", default: false)
    var isShowMonthProduct: Bool
    
    @RemoteKonfigProperty(key: "i340_is_show_year", default: true)
    var isShowYearProduct: Bool

    /// Percentage of a free-trial plan's StoreKit price reported as predicted value.
    @RemoteKonfigProperty(key: "i340_free_trial_predict_percent_value", default: 20.0)
    var freeTrialPredictPercentValue: Double

    /// JSON object containing `iapEndPoint` and `iapApiKey` for verified-purchase delivery.
    @RemoteKonfigProperty(key: "i340_notification_env", default: "")
    var notificationEnvironment: String
    
    // MARK: - Other Configs

    @RemoteKonfigProperty(key: "App_Time_Translator", default: "")
    var TimeTranslator: String

    @RemoteKonfigProperty(key: "App_Time_Scanner", default: "")
    var TimeDetect: String

    @RemoteKonfigProperty(key: "gemini_ai_model", default: "gemini-2.5-flash")
    var geminiAIModel: String

    @RemoteKonfigProperty(key: "gemini_ai_key", default: "your_gemini_api_key")
    var geminiAIKey: String

    @RemoteKonfigProperty(key: "i340_navigate_reinstalling", default: "")
    var navigateReinstall: String
}
