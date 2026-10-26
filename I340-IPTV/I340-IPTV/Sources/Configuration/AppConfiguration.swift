//
//  AppConfiguration.swift
//  I340_IPTV
//

import Foundation

/// Reads the `AppConfigs` dictionary of the Info.plist (per-app ids, keys and switches).
final class AppConfiguration {
    static let shared = AppConfiguration()
    private var appInfos: [String: Any] = [:]
    private var advertisementInfos: [String: Any] = [:]
    private var inAppPurcharseInfos: [String: Any] = [:]
    private var localNotificationInfos: [String: Any] = [:]
    private var domain: [String: Any] = [:]
    private var trackingInfos: [String: Any] = [:]

    private init() {
        readAppConfigInfo()
    }
    
    func adString(_ key: Configs.AdvertisementID) -> String {
        return advertisementInfos[key.name] as? String ?? ""
    }
    
    func applicationID() -> String {
        return appInfos["ApplicationID"] as! String
    }
    func emailDeveloper() -> String {
        return appInfos["EmailDeveloper"] as? String ?? ""
    }
    func appGroupID() -> String {
        return appInfos["AppGroupID"] as! String
    }
    func enableShowReviewDialog() -> Bool {
        if let value = advertisementInfos["EnableShowAds"] as? String, value == "YES" {
            return true
        } else {
            return false
        }
    }
    func privacyPolicyUrl() -> String {
        return appInfos["PrivacyPolicyUrl"] as! String
    }
    func termOfUseUrl() -> String {
        return appInfos["TermOfUseUrl"] as! String
    }
    
    func tiktokAppId() -> String {
        return trackingInfos["TikTokAppID"] as? String ?? ""
    }
    
    func tikTokAccessToken() -> String {
        return trackingInfos["TikTokAccessToken"] as? String ?? ""
    }
    
    func iAPSubcriptionSecret() -> String {
        return inAppPurcharseInfos["IAPSubcriptionSecret"] as! String
    }

    func enableShowInApp() -> Bool {
        if let value = inAppPurcharseInfos["EnableShowInApp"] as? String, value == "YES" {
            return true
        }
        return false
    }

    func enableShowInAppWhenOpenApp() -> Bool {
        if let value = inAppPurcharseInfos["EnableShowInAppWhenOpenApp"] as? String, value == "YES" {
            return true
        }
        return false
    }
    
    func iAPOneTime() -> String {
        return inAppPurcharseInfos["OneTime"] as! String
    }

    func iAPWeekly() -> String {
        return inAppPurcharseInfos["IAPWeekly"] as? String ?? ""
    }
    
    func iAPMiniPackage() -> String {
        return inAppPurcharseInfos["IAPMiniPackage"] as? String ?? ""
    }
    
    func iAPMonthly() -> String {
        return inAppPurcharseInfos["IAPMonthly"] as! String
    }
    
    func iAPYearly() -> String {
        return inAppPurcharseInfos["IAPYearly"] as! String
    }
    
    func iAPYearlySaleOff() -> String {
        return inAppPurcharseInfos["IAPYearlySaleOff"] as? String ?? ""
    }
    
    func infoPremium() -> [String] {
        return inAppPurcharseInfos["InfoPremium"] as! [String]
    }
    
    func iAPMessage() -> String {
        return inAppPurcharseInfos["IAPMessage"] as! String
    }
    
    func enableLocalNotification() -> Bool {
        if let value = localNotificationInfos["EnableLocalNotification"] as? String, value == "YES" {
            return true
        } else {
            return false
        }
    }
    
    func timeTriggerNotification() -> TimeInterval {
        if let value = localNotificationInfos["TimeTriggerNotification"] as? String, let time = TimeInterval(value) {
            return time
        }
        return 86400
    }
    
    func contentTrigger() -> [(title: String, body: String)] {
        let dict = localNotificationInfos["ContentTrigger"] as! NSDictionary
        var messages: [(title: String, body: String)] = []
        dict.forEach({ item in
            messages.append((title: item.key as! String, body: item.value as! String))
        })
        return messages
    }
    
    func trackingUrl() -> String {
        return domain["SearchAdsTrackingDomain"] as! String
    }
    
    private func readAppConfigInfo() {
        appInfos = AppConfiguration.stringValue(forKey: "AppInfo") as! [String : Any]
        domain =  AppConfiguration.stringValue(forKey: "Server") as! [String : Any]
        advertisementInfos = AppConfiguration.stringValue(forKey: "Advertisement") as! [String : Any]
        inAppPurcharseInfos = AppConfiguration.stringValue(forKey: "InAppPurchase") as! [String : Any]
        localNotificationInfos = AppConfiguration.stringValue(forKey: "LocalNotification") as! [String : Any]
        trackingInfos = AppConfiguration.stringValue(forKey: "Tracking") as! [String : Any]
    }
}

extension AppConfiguration {
    static func stringValue(forKey key: String) -> Any {
        guard let appConfigs = Bundle.main.object(forInfoDictionaryKey: "AppConfigs") as? Dictionary<String, Any>
        else {
            fatalError("Invalid value or undefined key")
        }
        guard let value = appConfigs[key]
        else {
            fatalError("Invalid value or undefined key")
        }
        return value
    }
}
