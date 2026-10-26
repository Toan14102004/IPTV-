//
//  AdsManager.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import UIKit
import GoogleMobileAds
import FBAudienceNetwork
import AppLovinSDK
import MTGSDK
import GoogleMobileAds
import RxSwift

final class AdsManager: NSObject {
    static let shared = AdsManager()
    
    // Ad managers
    var interstitialAdUtils: InterstitialAdHandler!
    var openInterstitialFirstUtils: InterstitialAdHandler!
    var openInterstitialAd2FUtils: InterstitialAdHandler!
    var openInterstitialAdMFUtils: InterstitialAdHandler!
    var backgroundInterstitialUtils: InterstitialAdHandler!
    var nativeAdUtils: SingleNativeAdHandler!
    var listNativeAdUtils: ListNativeAdHandler!
    var rewardedAdUtils: RewardedAdHandler!
    var appOpenAdUtils: AppOpenAdUtils!
    
    private var disableAppOpenAdVCs: [AnyClass] = []
    /// Set by SwiftUI screens (which are not `UIViewController` subclasses) that must not show app-open ads.
    var isAppOpenAdSuppressed = false
    private var lastTimeShowInterstitialAd: TimeInterval = 0
    private var timeIntervalShowInterstitialAd: TimeInterval = TimeInterval(RemoteKonfig.shared.delayShowIntervalInterstitial)
    private var lastTimeShowOpenAd: TimeInterval = 0
    private var isMobileAdsInitializeCalled = false
    private var isAfterFlow2F = false
    
    private var currentActivity: UIViewController?
    
    // MARK: - Skip Appear Mechanism (Private Properties)
    
    private let skipAppearLock = NSLock()
    private var skipAppearState: [ObjectIdentifier: Int] = [:]   // VC -> number of times to skip
    private var isPresentingFullScreenAd = false
    
    override init() {
        super.init()
        setupLifecycleObserver()
    }
    
    func configure(
        disableAppOpenAdVCs: [AnyClass] = [],
        numberOfAdsToLoad: Int = 5
    ) {
        self.disableAppOpenAdVCs = disableAppOpenAdVCs
        
        // Initialize ad managers
        interstitialAdUtils = InterstitialAdHandler(
            adId: .ADSInterstitialAdsID,
            type: .COMMON
        )

        openInterstitialFirstUtils = InterstitialAdHandler(
            adId: Configs.AdvertisementID.ADSInterstitialOpenAppID,
            type: .OPEN,
            retry: 0
        )
        
        openInterstitialAd2FUtils = InterstitialAdHandler(
            adId: Configs.AdvertisementID.ADSInterstitialOpenApp2FID,
            type: .OPEN,
            retry: Int.max
        )
        
        openInterstitialAdMFUtils = InterstitialAdHandler(
            adId: Configs.AdvertisementID.ADSInterstitialOpenAppMFID,
            type: .OPEN,
            retry: 0
        )
        
        backgroundInterstitialUtils = InterstitialAdHandler(
            adId: Configs.AdvertisementID.ADSInterstitialBackgroundID,
            type: .BACKGROUND
        )
        
        nativeAdUtils = SingleNativeAdHandler()
        listNativeAdUtils = ListNativeAdHandler(numberOfAdsToLoad: numberOfAdsToLoad)
        rewardedAdUtils = RewardedAdHandler.shared
        rewardedAdUtils.initWithMultipleIds([.ADSRewardedVideoAds2FID, .ADSRewardedVideoAdsMFID, .ADSRewardedVideoAdsID])
        appOpenAdUtils = AppOpenAdUtils.shared
    }
    
    func gatherConsent(
        from viewController: UIViewController,
        onCompletion: @escaping (String?) -> Void,
        isHighFloor: Bool = true
    ) {
        isMobileAdsInitializeCalled = false
        
        // Request IDFA and consent
        TrackingUsageUtils.shared.gatherConsent(from: viewController) { [weak self] consentError in
            guard let self = self else { return }
            
            if let consentError = consentError {
                print("AdsManager: Consent error - \(consentError.localizedDescription)")
            }
            
            self.initializeAdsAndTracking(isHighFloor)
            
            onCompletion(consentError?.localizedDescription)
        }
        
        // This sample attempts to load ads using consent obtained in the previous session.
        if TrackingUsageUtils.shared.canRequestAds {
            initializeMobileAdsSdk(isHighFloor: isHighFloor)
        }
    }
    
    private func initializeAdsAndTracking(_ isHighFloor: Bool) {
        // ---- Combine the two privacy signals ----
        let umpOK = TrackingUsageUtils.shared.canRequestAds
        let canUsePersonalisedAds = umpOK && TrackingUsageUtils.isATTAuthorized
        
        // ---- Configure ad networks ----
        FBAdSettings.setAdvertiserTrackingEnabled(canUsePersonalisedAds)
        ALPrivacySettings.setHasUserConsent(canUsePersonalisedAds)
        ALPrivacySettings.setDoNotSell(!canUsePersonalisedAds)
        MTGSDK.sharedInstance().consentStatus = canUsePersonalisedAds
        MTGSDK.sharedInstance().doNotTrackStatus = !canUsePersonalisedAds
        
        // ---- Initialize tracking ----
        EventTrackingHelper.shared.startWith()
        
        // ---- Start Google Mobile Ads / mediation SDKs ----
        if umpOK && !IAPHelper.shared().isSubscribed() {
            self.initializeMobileAdsSdk(isHighFloor: isHighFloor)
        }
        
    }
    
    private func initializeMobileAdsSdk(isHighFloor: Bool) {
        if isMobileAdsInitializeCalled {
            return
        }
        isMobileAdsInitializeCalled = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Initialize the Google Mobile Ads SDK.
            MobileAds.shared.start { status in
                print("AdsManager: AdMob SDK initialized: \(status.adapterStatusesByClassName)")
            }
            
            // Load ads on the main thread.
            if !IAPHelper.shared().isSubscribed() {
                if isHighFloor {
                    self.openInterstitialAd2FUtils.loadAd(isRefresh: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.openInterstitialAdMFUtils.loadAd(isRefresh: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.openInterstitialFirstUtils.loadAd(isRefresh: true)
                        }
                    }
                } else {
                    self.openInterstitialFirstUtils.loadAd(isRefresh: true)
                }
                
                self.interstitialAdUtils.loadAd(isRefresh: true)
                self.backgroundInterstitialUtils.loadAd(isRefresh: true)
            }
        }
    }
    
    // MARK: - Inter
    
    func showInterAd(
        from viewController: UIViewController,
        immediate: Bool = false,
        callback: @escaping (Bool) -> Void
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            callback(false)
            return
        }
        
        if showInter2FIfAvailable(from: viewController, callback: callback) {
            return
        }
        
        interstitialAdUtils.showAd(
            from: viewController,
            onAdsShowed: {},
            onAdsClosed: { isUserInteraction in
                callback(isUserInteraction)
            }
        )
    }

    func showInter2FIfAvailable(
        from viewController: UIViewController,
        callback: @escaping (Bool) -> Void
    ) -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds else { return false }
        
        if openInterstitialAd2FUtils.isAdAvailable() {
            openInterstitialAd2FUtils.showAd(
                from: viewController,
                onAdsShowed: {},
                onAdsClosed: { isUserInteraction in
                    callback(isUserInteraction)
                }
            )
            return true
        }
        
        if openInterstitialAdMFUtils.isAdAvailable() {
            openInterstitialAdMFUtils.showAd(
                from: viewController,
                onAdsShowed: {},
                onAdsClosed: { isUserInteraction in
                    callback(isUserInteraction)
                }
            )
            return true
        }
        
        if openInterstitialFirstUtils.isAdAvailable() {
            openInterstitialFirstUtils.showAd(
                from: viewController,
                onAdsShowed: {},
                onAdsClosed: { isUserInteraction in
                    callback(isUserInteraction)
                }
            )
            return true
        }
        
        return false // 2F not available
    }
    
    func updateIsAfterFlow2F(_ value: Bool) {
        isAfterFlow2F = value
    }
    
    func updateTimeIntervalShowInterstitialAd(_ interval: Int) {
        timeIntervalShowInterstitialAd = TimeInterval(interval)
    }
    
    func updateLastTimeShowInterstitialAd(_ value: TimeInterval) {
        lastTimeShowInterstitialAd = value
    }
    
    func getLastTimeShowInterstitialAd() -> TimeInterval {
        return lastTimeShowInterstitialAd
    }
    
    func getTimeIntervalShowInterstitialAd() -> TimeInterval {
        return timeIntervalShowInterstitialAd
    }
    
    func updateLastTimeShowOpenAd(_ value: TimeInterval) {
        lastTimeShowOpenAd = value
    }
    
    // MARK: - Native
    
    func preloadNativeAd(
        _ slot: Configs.AdvertisementID,
        autoReload: Bool = false,
        onAdLoaded: ((NativeAd?, Error?) -> Void)? = nil
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            onAdLoaded?(nil, nil)
            return
        }
        
        nativeAdUtils.loadAd(slot: slot, isPreload: true, autoReload: autoReload, onAdLoaded: onAdLoaded)
    }
    
    func refreshNativeAd(
        _ slot: Configs.AdvertisementID = .ADSNativeAdsMediaViewID,
        onAdLoaded: ((NativeAd?, Error?) -> Void)? = nil
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            onAdLoaded?(nil, nil)
            return
        }
        
        if let native2FAd = getNative2FIfAvailable() {
            onAdLoaded?(native2FAd, nil)
            return
        }
        
        nativeAdUtils.loadAd(slot: slot, isPreload: false, isRefresh: true, onAdLoaded: onAdLoaded)
    }
    
    // Backward compatibility methods
    func getNativeAdById(_ adId: Configs.AdvertisementID) -> NativeAd? {
        guard Configs.Advertisement.canRequestAndShowAds else { return nil }
        return nativeAdUtils.getAdById(adId)
    }
    
    func getPreloadNativeAdById(_ adId: Configs.AdvertisementID) -> NativeAd? {
        guard Configs.Advertisement.canRequestAndShowAds else { return nil }
        return nativeAdUtils.getAdById(adId)
    }
    
    func hasPreloadedNativeAd(_ adId: Configs.AdvertisementID) -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds else { return false }
        return nativeAdUtils.isAdAvailable(slotName: adId.name)
    }
    
    private func getNative2FIfAvailable() -> NativeAd? {
        if !isAfterFlow2F {
            return nil
        }
        
        if let ad = nativeAdUtils.getFirst2FAd() {
            print("AdsManager: Show 2F ad: \(ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown")")
            return ad
        }
        
        if let ad = nativeAdUtils.getFirstMFAd() {
            print("AdsManager: Show MF ad: \(ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown")")
            return ad
        }
        
        if let ad = nativeAdUtils.getFirstAPAd() {
            print("AdsManager: Show MF ad: \(ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown")")
            return ad
        }
        
        return nil
    }
    
    func subscribeNativeAds() -> Observable<[NativeAd]> {
        listNativeAdUtils.nativeAds$
    }
    
    func loadListNativeAds(id: Configs.AdvertisementID = Configs.AdvertisementID.ADSNativeAdsNoMediaViewID, quantity: Int = 5) {
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        listNativeAdUtils.loadAds(id: id, quantity: quantity)
    }

    func isFullScreenAdAvailable() -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds else { return false }
        
        let adIds: [Configs.AdvertisementID] = [
            .ADSNativeFullScreen2FID,
            .ADSNativeFullScreenMFID,
            .ADSNativeFullScreenID
        ]

        return adIds.contains { nativeAdUtils.isAdAvailable(slotName: $0.name) }
    }
    
    // MARK: - Reward
    
    func showRewardAd(
        from viewController: UIViewController,
        onAdClosed: @escaping ((_ hasReward: Bool) -> Void),
        onPresentFailed: (() -> Void)?
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            onAdClosed(false)
            return
        }
        
        rewardedAdUtils.showAd(from: viewController, onAdClosed: onAdClosed, onPresentFailed: onPresentFailed)
    }
    
    // MARK: - Lifecycle Observer
    
    private func setupLifecycleObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func applicationWillEnterForeground() {
        guard Configs.Advertisement.canRequestAndShowAds else { return }
        
        guard let rootViewController = getCurrentViewController() else { return }
        
        // Check if another full screen ad is being displayed
        if getIsPresentingFullScreenAd() {
            print("AdsManager: Another full screen ad are being displayed. Do not show app open ad over overlapping")
            return
        }

        if UserDefaultManager.shared().isShowNativeFull {
            print("AdsManager: Native full screen ad is being displayed. Do not show inter background ad.")
            return
        }
        
        // Check if current view controller is in disable list
        if isAppOpenAdSuppressed || disableAppOpenAdVCs.contains(where: { rootViewController.isKind(of: $0) == true }) {
            print("AdsManager: \(String(describing: rootViewController)) disabled show app open ad.")
            return
        }
        
        // Try to show 2F interstitial first
        if showInter2FIfAvailable(from: rootViewController, callback: { _ in }) {
            return
        }
        
        // Show background interstitial
        backgroundInterstitialUtils.showAd(
            from: rootViewController,
            isComeback: true,
            onAdsShowed: {},
            onAdsClosed: { _ in }
        )
    }
    
    @available(iOS 13, *)
    private func getCurrentViewController(base: UIViewController? = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController) -> UIViewController? {
        
        if let presented = base?.presentedViewController {
            return getCurrentViewController(base: presented)
        }
        
        if let nav = base as? UINavigationController {
            return getCurrentViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return getCurrentViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return getCurrentViewController(base: presented)
        }
        return base
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Skip Appear Mechanism (Counter-based)

extension AdsManager {
    /// Call before showing any full-screen overlay/ad
    func armSkipAppear(for vc: UIViewController, count: Int = 1) {
        skipAppearLock.lock()
        defer { skipAppearLock.unlock() }
        let key = ObjectIdentifier(vc)
        skipAppearState[key] = max(count, skipAppearState[key] ?? 0)
    }
    
    /// Called by BaseVC to consume one skip
    func consumeSkipAppearIfArmed(for vc: UIViewController) -> Bool {
        skipAppearLock.lock()
        defer { skipAppearLock.unlock() }
        let key = ObjectIdentifier(vc)
        guard let n = skipAppearState[key], n > 0 else { return false }
        let next = n - 1
        if next == 0 {
            skipAppearState.removeValue(forKey: key)
        } else {
            skipAppearState[key] = next
        }
        return true
    }
    
    func setPresentingFullScreenAd(_ value: Bool) {
        skipAppearLock.lock()
        isPresentingFullScreenAd = value
        skipAppearLock.unlock()
    }
    
    func getIsPresentingFullScreenAd() -> Bool {
        skipAppearLock.lock()
        defer { skipAppearLock.unlock() }
        return isPresentingFullScreenAd
    }
}
