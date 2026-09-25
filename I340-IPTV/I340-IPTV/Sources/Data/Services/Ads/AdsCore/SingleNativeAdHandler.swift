//
//  SingleNativeAdHandler.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import UIKit
import GoogleMobileAds
import RxRelay
import RxSwift
import ObjectiveC
import AdsDebugKit

/// Ad configuration for auto-reload tracking
struct AdReloadConfig {
    let slot: Configs.AdvertisementID
    var isReloading: Bool
    var remainingRetries: Int
}

final class SingleNativeAdHandler: NSObject {
    
    // MARK: - Constants
    private static let RETRY_DELAY_SECONDS: TimeInterval = 3.0
    private static let MAX_RETRY_COUNT: Int = 10
    private static let NO_FILL_ERROR_CODE = 1  // No fill error
    private static let NETWORK_ERROR_CODES = [2, 3]  // Network errors

    // Keep loaders strongly so delegate callbacks fire. Use UUID to allow concurrent loads.
    private var loaders: [UUID: AdLoader] = [:]

    private let nativeAdWithIdMap   = NSMutableDictionary()
    private let nativeAd2FWithIdMap = NSMutableDictionary()
    private let nativeAdMFWithIdMap = NSMutableDictionary()
    // private var isRefeshing = false // REMOVED: Shared state causes race conditions
    
    // Auto-reload tracking
    private var adReloadMap: [String: AdReloadConfig] = [:]
    private let bag = DisposeBag()

    // MARK: - Associated Object Keys (must be stable pointers)
    struct AssocKeys {
        static var adLoadedCallback: UInt8 = 0
        static var slot: UInt8 = 0
        static var isRefresh: UInt8 = 0
        static var loaderId: UInt8 = 0
    }
    
    override init() {
        super.init()
        NetworkOverlayManager.shared.isConnectedSubject
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    self.retryOnNetworkAvailable()
                }
            })
            .disposed(by: bag)
    }

    func loadAd(
        slot: Configs.AdvertisementID,
        isPreload: Bool,
        isRefresh: Bool = false,
        autoReload: Bool = false,
        onAdLoaded: ((NativeAd?, Error?) -> Void)? = nil
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            onAdLoaded?(nil, nil)
            return
        }
        
        guard !IAPHelper.shared().isSubscribed() else {
            print("SingleNativeAdHandler: App not allow to show ad.")
            return
        }
        guard TrackingUsageUtils.shared.canRequestAds else {
            print("SingleNativeAdHandler: Mobile Ads consent manager cannot request ads.")
            return
        }
        
        let adUnitID = slot.id
        let slotName = slot.name
        
        // Check if this slot is loading by any loaders??
        let isAlreadyLoading = loaders.values.contains { loader in
            let loadingSlot = objc_getAssociatedObject(loader, &AssocKeys.slot) as? Configs.AdvertisementID
            return loadingSlot?.name == slotName
        }
        
        if isAlreadyLoading {
            print("SingleNativeAdHandler: Slot \(slotName) is already loading. Skip this request to prevent pile-up.")
            return
        }

        if !isRefresh { // not refresh ad so check if it exists
            if !isPreload, let ad = getAdById(slot) {
                print("SingleNativeAdHandler: NativeAd with slot \(slotName) already exists, get existing ad...")
                onAdLoaded?(ad, nil)
                return
            } else if isPreload, isAdAvailable(slotName: slotName) {
                print("SingleNativeAdHandler: NativeAd with slot \(slotName) already exists.")
                return
            }
        }
        
        // Setup auto-reload configuration
        if autoReload, adReloadMap[slotName] == nil {
            let config = AdReloadConfig(
                slot: slot,
                isReloading: true,
                remainingRetries: Self.MAX_RETRY_COUNT
            )
            adReloadMap[slotName] = config
        } else {
            adReloadMap[slotName]?.isReloading = true
        }
        
        // isRefeshing = isRefresh // REMOVED

        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true

        // Resolve a non-nil root view controller
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController

        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootVC, // must not be nil
            adTypes: [.native],
            options: [videoOptions]
        )
        adLoader.delegate = self

        // Keep loader alive using a unique ID
        let loaderId = UUID()
        loaders[loaderId] = adLoader
        print("SingleNativeAdHandler: Created loader \(loaderId). Active loaders: \(loaders.count)")

        // Store metadata via associated objects
        if let callback = onAdLoaded {
            objc_setAssociatedObject(adLoader, &AssocKeys.adLoadedCallback, callback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        objc_setAssociatedObject(adLoader, &AssocKeys.slot, slot, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(adLoader, &AssocKeys.isRefresh, isRefresh, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(adLoader, &AssocKeys.loaderId, loaderId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // for debug
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .loadStart,
            adId: slot
        ))

        adLoader.load(Request())
    }
    
    func getAdById(_ adId: Configs.AdvertisementID) -> NativeAd? {
        guard Configs.Advertisement.canRequestAndShowAds else { return nil }
        
        let slotName = adId.name
        
        // Try to find by slot name first
        if let ad = nativeAd2FWithIdMap[slotName] as? NativeAd {
            nativeAd2FWithIdMap.removeObject(forKey: slotName)
            triggerAutoReloadIfNeeded(slotName: slotName)
            return ad
        }
        
        if let ad = nativeAdMFWithIdMap[slotName] as? NativeAd {
            nativeAdMFWithIdMap.removeObject(forKey: slotName)
            triggerAutoReloadIfNeeded(slotName: slotName)
            return ad
        }
        
        if let ad = nativeAdWithIdMap[slotName] as? NativeAd {
            nativeAdWithIdMap.removeObject(forKey: slotName)
            triggerAutoReloadIfNeeded(slotName: slotName)
            return ad
        }
        triggerAutoReloadIfNeeded(slotName: slotName)
        return nil
    }
    
    func addAds(adId: String, ad: NativeAd) {
        nativeAdWithIdMap[adId] = ad
    }
    
    func getLastAd() -> NativeAd? {
        guard let lastKey = nativeAdWithIdMap.allKeys.last as? String,
              let ad = nativeAdWithIdMap[lastKey] as? NativeAd else {
            return nil
        }
        nativeAdWithIdMap.removeObject(forKey: lastKey)
        
        // Trigger auto-reload if configured
        triggerAutoReloadIfNeeded(slotName: lastKey)
        
        return ad
    }
    
    func getFirst2FAd() -> NativeAd? {
        guard let firstKey = nativeAd2FWithIdMap.allKeys.first as? String,
              let ad = nativeAd2FWithIdMap[firstKey] as? NativeAd else {
            return nil
        }
        nativeAd2FWithIdMap.removeObject(forKey: firstKey)
        
        // Trigger auto-reload if configured
        triggerAutoReloadIfNeeded(slotName: firstKey)
        
        return ad
    }
    
    func getFirstMFAd() -> NativeAd? {
        guard let firstKey = nativeAdMFWithIdMap.allKeys.first as? String,
              let ad = nativeAdMFWithIdMap[firstKey] as? NativeAd else {
            return nil
        }
        nativeAdMFWithIdMap.removeObject(forKey: firstKey)
        
        // Trigger auto-reload if configured
        triggerAutoReloadIfNeeded(slotName: firstKey)
        
        return ad
    }
    
    func getFirstAPAd() -> NativeAd? {
        guard let firstKey = nativeAdWithIdMap.allKeys.first as? String,
              let ad = nativeAdWithIdMap[firstKey] as? NativeAd else {
            return nil
        }
        nativeAdWithIdMap.removeObject(forKey: firstKey)
        
        // Trigger auto-reload if configured
        triggerAutoReloadIfNeeded(slotName: firstKey)
        
        return ad
    }
    
    // MARK: - Auto-Reload Methods
    
    private func retryPreLoadAd(config: AdReloadConfig) {
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        
        guard var updatedConfig = adReloadMap[config.slot.name] else { return }
        
        let nextRemaining = updatedConfig.remainingRetries - 1
        updatedConfig.remainingRetries = nextRemaining
        adReloadMap[config.slot.name] = updatedConfig
        
        guard nextRemaining >= 0 else {
            print("SingleNativeAdHandler: [\(config.slot.name)] Retry count exhausted or auto-reload disabled → skip retry")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.RETRY_DELAY_SECONDS) { [weak self] in
            guard let self = self else { return }
            print("SingleNativeAdHandler: [\(config.slot.name)] Retrying load ad after delay (remaining retries: \(nextRemaining))")
            self.loadAd(
                slot: config.slot,
                isPreload: true,
                isRefresh: false,
                autoReload: true
            )
        }
    }
    
    /// Call this method when network becomes available to retry pending ads
    func retryOnNetworkAvailable() {
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        
        let adsToReload = adReloadMap.filter { !$0.value.isReloading }
        guard !adsToReload.isEmpty else { return }
        
        print("SingleNativeAdHandler: Try to reload \(adsToReload.count) native ads after network available")
        
        for config in adsToReload.values {
            triggerAutoReloadIfNeeded(slotName: config.slot.name)
        }
    }
    
    private func triggerAutoReloadIfNeeded(slotName: String) {
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        
        // Try to find matching config for any type
        if !isAdAvailable(slotName: slotName), let config = adReloadMap[slotName], !config.isReloading {
            print("SingleNativeAdHandler: [\(slotName)] Ad consumed, triggering auto-reload")
            
            // Trigger reload with delay
            retryPreLoadAd(config: config)
        }
    }
    
    /// Check if ad is available for a given slot name
    func isAdAvailable(slotName: String) -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds else { return false }
        
        return nativeAdWithIdMap[slotName] != nil ||
               nativeAd2FWithIdMap[slotName] != nil ||
               nativeAdMFWithIdMap[slotName] != nil
    }
}

extension SingleNativeAdHandler: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        // Read metadata set on loader
        let slot = (objc_getAssociatedObject(adLoader, &AssocKeys.slot) as? Configs.AdvertisementID)
            ?? Configs.AdvertisementID.ADSNativeAdsMediaViewID
        let slotName = slot.name

        let isRefresh = (objc_getAssociatedObject(adLoader, &AssocKeys.isRefresh) as? Bool) ?? false
        let loaderId = objc_getAssociatedObject(adLoader, &AssocKeys.loaderId) as? UUID
        
        print("SingleNativeAdHandler: Loaded nativeAd \(nativeAd) with slot \(slotName).")

        let network = nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName
        let lineItem = nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName

        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .loadSuccess,
            adId: slot,
            network: network,
            lineItem: lineItem
        ))
        
        // Reset retry count on successful load
        if var config = adReloadMap[slot.name] {
            config.remainingRetries = Self.MAX_RETRY_COUNT
            config.isReloading = false
            adReloadMap[slot.name] = config
        }
        
        /// Tracking ad revenue
        let adSourceName = nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
        nativeAd.paidEventHandler = { adValue in
            EventTrackingHelper.shared.handleAdPaidEvent(
                adRevenueNetwork: adSourceName,
                adValue: adValue,
                adId: slot,
                unit: .native
            )
        }
        nativeAd.delegate = self

        // Attach slotName and slotId to the ad object for later lookup
        objc_setAssociatedObject(nativeAd, &AssocKeys.slot, slot, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if !isRefresh { // if ads is fresh and take to load so not need to save
            // Place ad into the correct cache
            if slotName.contains("2FID") {
                nativeAd2FWithIdMap[slotName] = nativeAd
            } else if slotName.contains("MFID") {
                nativeAdMFWithIdMap[slotName] = nativeAd
            } else {
                nativeAdWithIdMap[slotName] = nativeAd
            }
        }
        
        // Fire callback if any
        if let callback = objc_getAssociatedObject(adLoader, &AssocKeys.adLoadedCallback) as? ((NativeAd?, Error?) -> Void) {
            callback(nativeAd, nil)
            // Clear callback to break potential retain cycles
            objc_setAssociatedObject(adLoader, &AssocKeys.adLoadedCallback, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Release loader after callback
        if let id = loaderId {
            loaders[id] = nil
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("SingleNativeAdHandler: Ad failed to load, error: \(error.localizedDescription).")
        
        let slot = (objc_getAssociatedObject(adLoader, &AssocKeys.slot) as? Configs.AdvertisementID)
            ?? Configs.AdvertisementID.ADSNativeAdsMediaViewID
        let loaderId = objc_getAssociatedObject(adLoader, &AssocKeys.loaderId) as? UUID
                
        if let callback = objc_getAssociatedObject(adLoader, &AssocKeys.adLoadedCallback) as? ((NativeAd?, Error?) -> Void) {
            callback(nil, error)
            // Clear callback to break potential retain cycles
            objc_setAssociatedObject(adLoader, &AssocKeys.adLoadedCallback, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        if let id = loaderId {
            loaders[id] = nil
        }
        
        /// for debug
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .loadFail,
            adId: slot,
            error: error.localizedDescription
        ))
        
        // Check error code
        let nsError = error as NSError
        let errorCode = nsError.code
        
        // Handle "no fill" error - pause ad loading completely
        if errorCode == Self.NO_FILL_ERROR_CODE {
            print("SingleNativeAdHandler: No fill error detected (code: \(errorCode)) → pause ad loading")
            if var config = adReloadMap[slot.name] {
                config.isReloading = false
                config.remainingRetries = 0 // Stop all retries
                adReloadMap[slot.name] = config
            }
            return
        }
        
        // Handle network error - retry when network is available (max 10 retries)
        if Self.NETWORK_ERROR_CODES.contains(errorCode) {
            print("SingleNativeAdHandler: Network error detected (code: \(errorCode)) → will retry when network available")
            if var config = adReloadMap[slot.name] {
                config.isReloading = false
                adReloadMap[slot.name] = config
            }
            return
        }
        
        // For other errors, retry if auto-reload is enabled
        if let config = adReloadMap[slot.name] {
            retryPreLoadAd(config: config)
        }
    }
}

extension SingleNativeAdHandler: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenNativeAdImpressionEvent)
        
        let slot = (objc_getAssociatedObject(nativeAd, &AssocKeys.slot) as? Configs.AdvertisementID)
            ?? Configs.AdvertisementID.ADSNativeAdsMediaViewID
        
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .impression,
            adId: slot,
            network: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
        
        print("SingleNativeAdHandler: [\(slot.name)] Ad impression recorded")
    }
    
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenNativeAdClickKey)
        
        let slot = (objc_getAssociatedObject(nativeAd, &AssocKeys.slot) as? Configs.AdvertisementID)
            ?? Configs.AdvertisementID.ADSNativeAdsMediaViewID
        
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .click,
            adId: slot,
            network: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
}
