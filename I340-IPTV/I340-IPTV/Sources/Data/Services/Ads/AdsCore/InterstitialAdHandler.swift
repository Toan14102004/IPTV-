//
//  InterstitialAdHandler.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import UIKit
import RxSwift
import GoogleMobileAds
import AdsDebugKit

enum InterstitialType {
    case COMMON
    case BACKWARD
    case OPEN
    case BACKGROUND
}

final class InterstitialAdHandler: NSObject {
    
    // MARK: - Constants
    private static let RETRY_DELAY_SECONDS: TimeInterval = 3.0
    private static let NO_FILL_ERROR_CODE = 1  // No fill error
    private static let NETWORK_ERROR_CODES = [2, 3]  // Network errors
    private static let MAX_NETWORK_RETRIES = 10  // Maximum network retry attempts
    
    private let adId: Configs.AdvertisementID
    private let type: InterstitialType
    
    /// The interstitial ad.
    private var interstitialAd: InterstitialAd?
    private var isShowingAd = false
    private var adDidComplete: (() -> Void)?
    private var isLoadFailed: Bool = false
    
    // Auto-reload tracking
    private var isReloading: Bool = false
    private let initRetryCount: Int
    private var remainingRetries: Int = 0
    private var networkRetryCount: Int = 0  // Track network retry attempts
    
    private let bag = DisposeBag()
    
    init(adId: Configs.AdvertisementID, type: InterstitialType, retry: Int = 1) {
        self.adId = adId
        self.type = type
        self.initRetryCount = retry
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
    
    // load ad or reset retry count if ad is loading
    func loadAd(isRefresh: Bool = false, successCallback: ((Bool) -> Void)? = nil) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            interstitialAd = nil
            isReloading = false
            successCallback?(false)
            return
        }
        
        remainingRetries = initRetryCount
        if !isReloading {
            isReloading = true
            startloadAd(isRefresh: isRefresh, successCallback: successCallback)
        }
    }
    
    private func startloadAd(isRefresh: Bool, successCallback: ((Bool) -> Void)? = nil) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            interstitialAd = nil
            isReloading = false
            successCallback?(false)
            return
        }
        
        if !isRefresh && isAdAvailable() {
            print("InterstitialAdHandler: Interstitial ad is available.")
            return
        }
        
        if IAPHelper.shared().isSubscribed() {
            print("InterstitialAdHandler: App not allow to load ad (subscribed).")
            return
        }
        
        if !TrackingUsageUtils.shared.canRequestAds {
            print("InterstitialAdHandler: Mobile Ads consent manager cannot request ads.")
            return
        }
        
        isLoadFailed = false
        
        AdTelemetry.shared.log(AdEvent(
            unit: .interstitial,
            action: .loadStart,
            adId: adId
        ))
        
        print("InterstitialAdHandler: Start loading interstitial ad.")
        InterstitialAd.load(
            with: adId.id,
            request: Request(),
            completionHandler: { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.interstitialAd = nil
                    self.isLoadFailed = true
                    successCallback?(false)
                    print("InterstitialAdHandler: Interstitial ad failed to load with error: \(error.localizedDescription).")
                    
                    AdTelemetry.shared.log(AdEvent(
                        unit: .interstitial,
                        action: .loadFail,
                        adId: self.adId,
                        error: error.localizedDescription
                    ))
                    
                    // Handle reload on error
                    self.handleLoadError(error: error)
                    return
                }
                
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                successCallback?(true)
                print("InterstitialAdHandler: Interstitial ad loaded successfully.")
                
                // Reset retry count on successful load
                self.remainingRetries = self.initRetryCount
                self.networkRetryCount = 0  // Reset network retry counter
                self.isReloading = false
                
                AdTelemetry.shared.log(AdEvent(
                    unit: .interstitial,
                    action: .loadSuccess,
                    adId: self.adId,
                    network: ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                    lineItem: ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
                ))
                
                /// Tracking ad revenue
                let adSourceName = ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
                ad?.paidEventHandler = { adValue in
                    EventTrackingHelper.shared.handleAdPaidEvent(
                        adRevenueNetwork: adSourceName,
                        adValue: adValue,
                        adId: self.adId,
                        unit: .interstitial
                    )
                }
            }
        )
    }
    
    func isAdAvailable() -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds else { return false }
        
        // Check if ad exists
        return interstitialAd != nil
    }
    
    func isTimeoutExpired() -> Bool {
        // Check if ad can be shown
        // Use shared delay from AdsManager for all inter ads
        let lastTimeShowAd = AdsManager.shared.getLastTimeShowInterstitialAd()
        let timeDistance = AdsManager.shared.getTimeIntervalShowInterstitialAd()
        return Date().timeIntervalSince1970 - lastTimeShowAd > timeDistance
    }
    
    func isLoadFail() -> Bool {
        return isLoadFailed
    }
    
    func showAd(
        from viewController: UIViewController,
        immediate: Bool = false,
        isComeback: Bool = false,
        onAdsShowed: @escaping () -> Void,
        onAdsClosed: @escaping (Bool) -> Void
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            interstitialAd = nil
            isShowingAd = false
            onAdsClosed(false)
            return
        }
        
        // If the ad is already showing, do not show the ad again.
        if isShowingAd {
            print("InterstitialAdHandler: Ad is already showing. Skipping.")
            onAdsClosed(false)
            return
        }
        
        // If the interstitial ad is not available yet but it is supposed to show,
        // it is considered to be complete in this example.
        if IAPHelper.shared().isSubscribed() {
            onAdsClosed(false)
            return
        }
        guard let ad = interstitialAd else {
            print("InterstitialAdHandler: Interstitial ad is not available yet.")
            loadAd(isRefresh: false)
            onAdsClosed(false)
            return
        }
        
        if !immediate && !isTimeoutExpired() {
            print("InterstitialAdHandler: Interstitial ad is not ready yet.")
            onAdsClosed(false)
            return
        }
        
        print("InterstitialAdHandler: Interstitial ad will be displayed.")
        
        ad.fullScreenContentDelegate = self
        
        let isCanPresent: Bool = ((try? ad.canPresent(from: viewController)) != nil)
        if isCanPresent {
            self.isShowingAd = true
            self.adDidComplete = { onAdsClosed(true) }
            
            AdTelemetry.shared.log(AdEvent(
                unit: .interstitial,
                action: .showStart,
                adId: adId,
                network: ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
                lineItem: ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
            ))
            
            AdsBackgroundWindowManager.shared.show(rootVC: viewController, isComeback: isComeback) {
                print("InterstitialAdHandler: Will show ad.")
                ad.present(from: AdsBackgroundWindowManager.shared.hostVC)
                
                onAdsShowed()
            }
        } else {
            print("InterstitialAdHandler: Cannot present ad.")
            
            interstitialAdManagerAdDidComplete()
            onAdsClosed(false)
        }
    }

    
    // MARK: - Auto-Reload Methods
    
    private func handleLoadError(error: Error) {
        let nsError = error as NSError
        let errorCode = nsError.code
        
        if errorCode == Self.NO_FILL_ERROR_CODE {
            print("InterstitialAdHandler: [\(adId.name)] No fill error detected (\(errorCode)) → stop loading ads")
            isReloading = false
            return
        }
        
        // Check if this is a network error
        let isNetworkError = Self.NETWORK_ERROR_CODES.contains(errorCode)
        
        if isNetworkError {
            if networkRetryCount >= Self.MAX_NETWORK_RETRIES {
                print("InterstitialAdHandler: [\(adId.name)] Network retry limit reached (\(networkRetryCount)/\(Self.MAX_NETWORK_RETRIES)) → stop retry")
                isReloading = false
                return
            }
            print("InterstitialAdHandler: [\(adId.name)] Network error detected (\(errorCode)) → will retry when network available (\(networkRetryCount)/\(Self.MAX_NETWORK_RETRIES))")
            isReloading = false
            return
        }
        
        // For other errors, retry if auto-reload is enabled
        retryLoadAd()
    }
    
    private func retryLoadAd() {
        guard remainingRetries > 0 else { return }
        
        let nextRemaining = remainingRetries - 1
        remainingRetries = nextRemaining
        
        guard nextRemaining >= 0 else {
            print("InterstitialAdHandler: [\(adId.name)] Retry count exhausted or auto-reload disabled → skip retry")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.RETRY_DELAY_SECONDS) { [weak self] in
            guard let self = self else { return }
            print("InterstitialAdHandler: [\(self.adId.name)] Retrying load ad after delay (remaining retries: \(nextRemaining))")
            self.startloadAd(isRefresh: false)
        }
    }
    
    /// Call this method when network becomes available to retry pending ads
    func retryOnNetworkAvailable() {
        guard !isAdAvailable() && !isReloading else { return }
        
        // Check if we've exceeded network retry limit
        if networkRetryCount >= Self.MAX_NETWORK_RETRIES {
            print("InterstitialAdHandler: [\(adId.name)] Network retry limit reached (\(networkRetryCount)/\(Self.MAX_NETWORK_RETRIES)) → skip retry")
            return
        }
        
        networkRetryCount += 1
        print("InterstitialAdHandler: [\(adId.name)] Reloading interstitial ad after network available (attempt \(networkRetryCount)/\(Self.MAX_NETWORK_RETRIES))")
        retryLoadAd()
    }
    
    private func interstitialAdManagerAdDidComplete() {
        // The interstitial ad is considered to be complete when it dismisses or fails to show,
        // call the delegate's interstitialAdManagerAdDidComplete method if the delegate is not nil.
        isShowingAd = false
        adDidComplete?()
        adDidComplete = nil
        AdsBackgroundWindowManager.shared.hide()
    }
}

// MARK: - GADFullScreenContentDelegate

extension InterstitialAdHandler: FullScreenContentDelegate {
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("InterstitialAdHandler: Ad present failed with error = \(error).")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .interstitial,
            action: .showFail,
            adId: adId,
            network: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName,
            error: error.localizedDescription
        ))
        
        interstitialAd = nil
        isShowingAd = false
        interstitialAdManagerAdDidComplete()
        
        // Trigger auto-reload after ad fails to present
        if !isReloading {
            retryLoadAd()
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("InterstitialAdHandler: Ad will present.")
        AdTelemetry.shared.log(AdEvent(
            unit: .interstitial,
            action: .showSuccess,
            adId: self.adId,
            network: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("InterstitialAdHandler: Ad dismiss.")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .interstitial,
            action: .dismiss,
            adId: adId,
            network: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
        
        // Update shared last time show ad for all inter ads
        AdsManager.shared.updateLastTimeShowInterstitialAd(Date().timeIntervalSince1970)
        interstitialAd = nil
        isShowingAd = false
        interstitialAdManagerAdDidComplete()
        
        // Trigger auto-reload after ad is consumed
        if !isReloading {
            retryLoadAd()
        }
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenInterAdClickKey)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .interstitial,
            action: .click,
            adId: adId,
            network: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: (ad as? InterstitialAd)?.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenInterAdImpressionEvent)
    }
}

