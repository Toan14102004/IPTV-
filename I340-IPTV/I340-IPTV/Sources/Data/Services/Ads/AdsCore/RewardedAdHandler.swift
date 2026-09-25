//
//  RewardedAdHandler.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import Foundation
import GoogleMobileAds
import AdsDebugKit

class RewardedAdHandler: NSObject {
    
    static let shared = RewardedAdHandler()
    
    private var rewardedAd: RewardedAd!
    
    private var rewardAdId: Configs.AdvertisementID!
    
    // Multi-ID loading support
    private var currentAdIndex = 0
    private var adUnitIDs: [Configs.AdvertisementID] = []
    private var loadedAdId: Configs.AdvertisementID? // Track the actual loaded ad ID
    
    private var onAdClosed: ((_ hasRewarded: Bool) -> Void)?
    private var onPresentFailed: (() -> Void)?
    
    private let nsLock = NSLock()
    private var hasReward = false
    private var isShowingAd = false
    
    func initWith(_ adId: Configs.AdvertisementID) {
        rewardAdId = adId
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        loadRewardAd()
    }
    
    func initWithMultipleIds(_ adUnitIDs: [Configs.AdvertisementID]) {
        self.adUnitIDs = adUnitIDs
        self.currentAdIndex = 0
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        loadRewardAd()
    }
    
    public func showAd(
        from viewController: UIViewController,
        onAdClosed: @escaping ((_ hasReward: Bool) -> Void),
        onPresentFailed: (() -> Void)? = nil
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            onAdClosed(false)
            return
        }
        
        if isShowingAd { return }
        nsLock.lock()
        defer { nsLock.unlock() }
        
        if IAPHelper.shared().isSubscribed() {
            onAdClosed(false)
            return
        }
        
        if !TrackingUsageUtils.shared.canRequestAds {
            finishShowingAd()
            onPresentFailed?()
            return
        }
        self.onAdClosed = onAdClosed
        self.onPresentFailed = onPresentFailed
        
        isShowingAd = true
        /// Show background ads view
        AdsBackgroundWindowManager.shared.show(rootVC: viewController) {[weak self] in
            guard let self = self else { return }
            loadRewardAd { [weak self] (ad, _) in
                guard let self = self else { return }
                if ad != nil {
                    /// Start show ad
                    do {
                        let hostVC = AdsBackgroundWindowManager.shared.hostVC
                        try rewardedAd.canPresent(from: hostVC)
                        
                        AdTelemetry.shared.log(AdEvent(
                            unit: .rewarded,
                            action: .showStart,
                            adId: loadedAdId ?? Configs.AdvertisementID.ADSRewardedVideoAdsID,
                            network: rewardedAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                            lineItem: rewardedAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
                        ))
                        
                        self.rewardedAd.present(from: hostVC, userDidEarnRewardHandler: {
                            self.hasReward = true
                        })
                        return
                    } catch {
                        AdTelemetry.shared.log(AdEvent(
                            unit: .rewarded,
                            action: .showFail,
                            adId: loadedAdId ?? Configs.AdvertisementID.ADSRewardedVideoAdsID,
                            network: rewardedAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                            lineItem: rewardedAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName,
                            error: error.localizedDescription
                        ))
                    }
                } else {
                    self.finishShowingAd()
                    self.onPresentFailed?()
                }
            }
        }
    }
    
    private func loadRewardAd(callback: ((RewardedAd?, Error?) -> Void)? = nil) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            callback?(nil, nil)
            return
        }
        
        if IAPHelper.shared().isSubscribed() {
            print("RewardedAdHandler: App not allow to load ad (subscribed).")
            return
        }
        
        if !TrackingUsageUtils.shared.canRequestAds {
            print("RewardedAdHandler: Mobile Ads consent manager cannot request ads.")
            return
        }
        
        // If adIds is empty, use the single rewardAdId
        if adUnitIDs.isEmpty {
            loadSingleAdId(adUnitID: rewardAdId, callback: callback)
        } else {
            // Use multi-ID loading with sequential attempts
            currentAdIndex = 0
            tryLoadNextAdSequentially(callback: callback)
        }
    }
    
    private func tryLoadNextAdSequentially(callback: ((RewardedAd?, Error?) -> Void)?) {
        guard currentAdIndex < adUnitIDs.count else {
            print("❗️RewardedAdHandler: All ads tried, none loaded successfully.")
            callback?(nil, NSError(domain: "RewardedAdHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "All ad IDs failed to load"]))
            return
        }
        
        let adId = adUnitIDs[currentAdIndex]
        var didFinish = false
        print("⏳ RewardedAdHandler: Attempting to load rewarded ad [index: \(currentAdIndex)] id: \(adId)")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .rewarded,
            action: .loadStart,
            adId: adId
        ))
        
        let timeoutTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !didFinish {
                print("⏰ RewardedAdHandler: Timeout loading ad [index: \(self.currentAdIndex)] id: \(adId)")
                self.currentAdIndex += 1
                self.tryLoadNextAdSequentially(callback: callback)
            }
        }
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeoutTask)
        
        RewardedAd.load(with: adId.id, request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            timeoutTask.cancel()
            
            guard !didFinish else { return }
            didFinish = true
            
            if let ad = ad {
                print("✅ RewardedAdHandler: Successfully loaded ad [index: \(self.currentAdIndex)] id: \(adId)")
                
                self.rewardedAd = ad
                self.rewardedAd.fullScreenContentDelegate = self
                self.loadedAdId = adId // Save the loaded ad ID
                callback?(ad, nil)
                
                AdTelemetry.shared.log(AdEvent(
                    unit: .rewarded,
                    action: .loadSuccess,
                    adId: adId,
                    network: ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                    lineItem: ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
                ))
                
                /// Tracking ad revenue
                let adSourceName = ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
                ad.paidEventHandler = { adValue in
                    EventTrackingHelper.shared.handleAdPaidEvent(
                        adRevenueNetwork: adSourceName,
                        adValue: adValue,
                        adId: adId,
                        unit: .rewarded
                    )
                }
            } else if let error = error {
                print("❌ RewardedAdHandler: Failed to load ad [index: \(self.currentAdIndex)] id: \(adId), error: \(error.localizedDescription)")
                
                AdTelemetry.shared.log(AdEvent(
                    unit: .rewarded,
                    action: .loadFail,
                    adId: adId,
                    error: error.localizedDescription
                ))
                
                self.currentAdIndex += 1
                self.tryLoadNextAdSequentially(callback: callback)
            }
        }
    }
    
    private func loadSingleAdId(adUnitID: Configs.AdvertisementID, callback: ((RewardedAd?, Error?) -> Void)?) {
        AdTelemetry.shared.log(AdEvent(
            unit: .rewarded,
            action: .loadStart,
            adId: Configs.AdvertisementID.ADSRewardedVideoAdsID
        ))
        
        RewardedAd.load(with: adUnitID.id, request: Request(), completionHandler: { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                callback?(nil, error)
                AdTelemetry.shared.log(AdEvent(
                    unit: .rewarded,
                    action: .loadFail,
                    adId: Configs.AdvertisementID.ADSRewardedVideoAdsID,
                    error: error.localizedDescription
                ))
                return
            }
            
            self.rewardedAd = ad
            self.rewardedAd.fullScreenContentDelegate = self
            self.loadedAdId = adUnitID // Save the loaded ad ID
            callback?(ad, nil)
            
            AdTelemetry.shared.log(AdEvent(
                unit: .rewarded,
                action: .loadSuccess,
                adId: Configs.AdvertisementID.ADSRewardedVideoAdsID,
                network: ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                lineItem: ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
            ))
            
            /// Tracking ad revenue
            let adSourceName = ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
            ad?.paidEventHandler = { adValue in
                EventTrackingHelper.shared.handleAdPaidEvent(
                    adRevenueNetwork: adSourceName,
                    adValue: adValue,
                    adId: Configs.AdvertisementID.ADSRewardedVideoAdsID,
                    unit: .rewarded
                )
            }
        })
    }
    
    private func finishShowingAd() {
        hasReward = false
        rewardedAd = nil
        isShowingAd = false
        AdsBackgroundWindowManager.shared.hide()
    }
}

extension RewardedAdHandler: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AdTelemetry.shared.log(AdEvent(
            unit: .rewarded,
            action: .showFail,
            adId: loadedAdId ?? Configs.AdvertisementID.ADSRewardedVideoAdsID,
            network: (ad as? RewardedAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? RewardedAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName,
            error: error.localizedDescription
        ))
        
        finishShowingAd()
        onPresentFailed?()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdTelemetry.shared.log(AdEvent(
            unit: .rewarded,
            action: .dismiss,
            adId: loadedAdId ?? Configs.AdvertisementID.ADSRewardedVideoAdsID,
            network: (ad as? RewardedAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? RewardedAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
        
        onAdClosed?(hasReward)
        finishShowingAd()
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        AdTelemetry.shared.log(AdEvent(
            unit: .rewarded,
            action: .click,
            adId: loadedAdId ?? Configs.AdvertisementID.ADSRewardedVideoAdsID,
            network: (ad as? RewardedAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? RewardedAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        AdTelemetry.shared.log(AdEvent(
            unit: .rewarded,
            action: .showSuccess,
            adId: loadedAdId ?? Configs.AdvertisementID.ADSRewardedVideoAdsID,
            network: self.rewardedAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: self.rewardedAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
}
