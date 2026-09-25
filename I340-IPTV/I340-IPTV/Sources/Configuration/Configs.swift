//
//  Configs.swift
//  I340_IPTV
//
//  Created by Nguyen Dao Hung on 9/6/26.
//

import Foundation
import AdsDebugKit

enum Configs {
    static let CURRENT_COIN = "CURRENT_COIN"
    static let require_update = "false"
    static var remote_URL = "https://your-api.com/api/v1/"
    static var isEnableMod = "false"
    
    enum InfoApp {
        static let appId = AppConfiguration.shared.applicationID()
        static var appIdWithoutIdPrefix: String {
            appId.hasPrefix("id") ? String(appId.dropFirst(2)) : appId
        }
        static let email = AppConfiguration.shared.emailDeveloper()
        static let enableShowReviewDialog = AppConfiguration.shared.enableShowReviewDialog()
        static let appGroup = AppConfiguration.shared.appGroupID()
        static let policyUrl = AppConfiguration.shared.privacyPolicyUrl()
        static let termOfUseUrl = AppConfiguration.shared.termOfUseUrl()
    }
    
    enum Network {
        static let perPage = 10
        static let networkTimeout: Double = 30
        static var Base_URL = "https://your-api.com/api/v1/"
        static let AES_SECRET = "YourAESSecretKey32CharactersLong"
        static let AES_IV = "YourAESIV16Chars"
        static let remoteConfigMinimumFetchInterval = 0.0
    }
    
    enum Advertisement {
        static let numberOfNativeAdsLoaded = 5
        static let offsetNativeAdsAndItem = 2
        static var canRequestAndShowAds: Bool { AppFlags.adsEnabled }
        static var canShowOpenAds = true
        static var isAfterFlow2F = false
    }

    enum notificationLocal {
        static let enableLocalNotification = AppConfiguration.shared.enableLocalNotification()
        static let timeTriggerNoti = AppConfiguration.shared.timeTriggerNotification()
        static let contentTrigger: [(title: String, body: String)] = AppConfiguration.shared.contentTrigger()
    }
    
    enum AppsFlyer {
        static let appsFlyerDevKey = AppConfiguration.shared.appsFlyerDevKey()
    }
    
    enum Domain {
        static let trackingUrl = AppConfiguration.shared.trackingUrl()
        static let refundURL = "https://issue.\(trackingUrl.replacingOccurrences(of: "https://appletracking.", with: ""))"
    }
    
    enum Tracking {
        static let tikTokAppId = AppConfiguration.shared.tiktokAppId()
        static let tikTokAccessToken = AppConfiguration.shared.tikTokAccessToken()
    }
}
