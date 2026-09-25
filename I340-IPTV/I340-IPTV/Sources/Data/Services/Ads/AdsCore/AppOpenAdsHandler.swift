//
//  AppOpenAdsHandler.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import GoogleMobileAds
import AdsDebugKit

final class AppOpenAdUtils: NSObject {
    static let shared = AppOpenAdUtils()
    
    /// Ad references in the app open beta will time out after four hours,
    /// but this time limit may change in future beta versions. For details, see:
    /// https://support.google.com/admob/answer/9341964?hl=en
    private let timeoutInterval: TimeInterval = 4 * 3_600
    /// The app open ad.
    private var appOpenAd: AppOpenAd?
    /// Keeps track of if an app open ad is loading.
    private var isLoadingAd = false
    /// Keeps track of if an app open ad is showing.
    private var isShowingAd = false
    /// Keeps track of the time when an app open ad was loaded to discard expired ad.
    private var loadTime: Date?
    
    private var rootController: UIViewController?
    
    var alreadyShowAds: Bool {
        get {
            return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInterval: timeoutInterval)
        }
    }
    
    func loadAd() {
        guard Configs.Advertisement.canRequestAndShowAds else {
            appOpenAd = nil
            isLoadingAd = false
            loadTime = nil
            return
        }
        
        // Do not load ad if there is an unused ad or one is already loading.
        if isLoadingAd || isAdAvailable() || IAPHelper.shared().isSubscribed() {
            return
        }
        
        if !TrackingUsageUtils.shared.canRequestAds {
            print("AppOpenAdsHandler: Mobile Ads consent manager cannot request ads.")
            return
        }
                
        isLoadingAd = true
        
        AdTelemetry.shared.log(AdEvent(
            unit: .appOpen,
            action: .loadStart,
            adId: Configs.AdvertisementID.ADSAppOpenAdsID
        ))
        
        print("AppOpenAdsHandler: Start loading app open ad.")
        AppOpenAd.load(
            with: Configs.AdvertisementID.ADSAppOpenAdsID.id,
            request: Request(),
            completionHandler: { [self] ad, error in
                self.isLoadingAd = false
                if let error = error {
                    self.appOpenAd = nil
                    self.loadTime = nil
                    print("AppOpenAdsHandler: App open ad failed to load with error: \(error.localizedDescription).")
                    
                    AdTelemetry.shared.log(AdEvent(
                        unit: .appOpen,
                        action: .loadFail,
                        adId: Configs.AdvertisementID.ADSAppOpenAdsID,
                        error: error.localizedDescription
                    ))
                    return
                }
                
                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.loadTime = Date()
                print("AppOpenAdsHandler: App open ad loaded successfully.")

                let network = ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName
                let lineItem = ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
                
                AdTelemetry.shared.log(AdEvent(
                    unit: .appOpen,
                    action: .loadSuccess,
                    adId: Configs.AdvertisementID.ADSAppOpenAdsID,
                    network: network,
                    lineItem: lineItem
                ))
                
                /// Tracking ad revenue
                let adSourceName = ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
                ad?.paidEventHandler = { adValue in
                    EventTrackingHelper.shared.handleAdPaidEvent(
                        adRevenueNetwork: adSourceName,
                        adValue: adValue,
                        adId: Configs.AdvertisementID.ADSAppOpenAdsID,
                        unit: .appOpen
                    )
                }
            }
        )
    }
    
    func isAdAvailable() -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds else { return false }
        
        // Check if ad exists and can be shown.
        return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInterval: timeoutInterval)
    }
    
    func showAdIfAvailable(viewController: UIViewController) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            appOpenAdManagerAdDidComplete()
            return
        }
        
        self.rootController = viewController
        // If the app open ad is already showing, do not show the ad again.
        if isShowingAd {
            print("AppOpenAdsHandler: Ad is already showing. Skipping.")
            return
        }
        
        // If the app open ad is not available yet but it is supposed to show,
        // it is considered to be complete in this example. Call the appOpenAdManagerAdDidComplete
        // method and load a new ad.
        
        
        if isAdAvailable() {
            if let appOpenAd = appOpenAd, let rootController = rootController {
                let isCanPresent: Bool = ((try? appOpenAd.canPresent(from: rootController)) != nil) && !isShowingAd
                if isCanPresent {
                    AdTelemetry.shared.log(AdEvent(
                        unit: .appOpen,
                        action: .showStart,
                        adId: Configs.AdvertisementID.ADSAppOpenAdsID,
                        network: appOpenAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                        lineItem: appOpenAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
                    ))
                    
                    AdsBackgroundWindowManager.shared.show(rootVC: viewController) {
                        print("AppOpenAdsHandler: Will show ad.")
                        appOpenAd.present(from: AdsBackgroundWindowManager.shared.hostVC)
                    }
                } else {
                    print("AppOpenAdsHandler: Cannot present ad.")
                    
                    appOpenAdManagerAdDidComplete()
                }
            } else {
                print("AppOpenAdsHandler: Not already show ad.")
                appOpenAdManagerAdDidComplete()
            }
        } else {
            print("AppOpenAdsHandler: Not already show ad.")
            appOpenAdManagerAdDidComplete()
            loadAd()
        }
    }
    
    func setShowingAdValue(_ showing: Bool) {
        self.isShowingAd = showing
    }
    
    private func wasLoadTimeLessThanNHoursAgo(timeoutInterval: TimeInterval) -> Bool {
        // Check if ad was loaded more than n hours ago.
        if let loadTime = loadTime {
            return Date().timeIntervalSince(loadTime) < timeoutInterval
        }
        return false
    }
    
    private func appOpenAdManagerAdDidComplete() {
        // The app open ad is considered to be complete when it dismisses or fails to show,
        // call the delegate's appOpenAdManagerAdDidComplete method if the delegate is not nil.
        isShowingAd = false
        rootController = nil
        AdsBackgroundWindowManager.shared.hide()
    }
}

// MARK: - GADFullScreenContentDelegate

extension AppOpenAdUtils: FullScreenContentDelegate {
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AppOpenAdsHandler: Ad present failed with error = \(error).")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .appOpen,
            action: .showFail,
            adId: Configs.AdvertisementID.ADSAppOpenAdsID,
            network: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName,
            error: error.localizedDescription
        ))
        
        appOpenAd = nil
        isShowingAd = false
        appOpenAdManagerAdDidComplete()
        loadAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AppOpenAdsHandler: Ad will present.")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .appOpen,
            action: .showSuccess,
            adId: Configs.AdvertisementID.ADSAppOpenAdsID,
            network: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AppOpenAdsHandler: Ad dismiss.")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .appOpen,
            action: .dismiss,
            adId: Configs.AdvertisementID.ADSAppOpenAdsID,
            network: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
        
        appOpenAd = nil
        isShowingAd = false
        appOpenAdManagerAdDidComplete()
        loadAd()
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenOpenAdClickKey)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .appOpen,
            action: .click,
            adId: Configs.AdvertisementID.ADSAppOpenAdsID,
            network: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? AppOpenAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenOpenAdImpressionEvent)
    }
}
