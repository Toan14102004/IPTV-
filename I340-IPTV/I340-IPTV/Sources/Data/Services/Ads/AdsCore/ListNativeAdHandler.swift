//
//  ListNativeAdHandler.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import UIKit
import GoogleMobileAds
import RxRelay
import RxSwift
import AdsDebugKit

final class ListNativeAdHandler: NSObject {
    var nativeAds$: Observable<[NativeAd]> { nativeAdsRelay.asObservable() }
    var nativeAdsCallback: (([NativeAd]) -> Void)? = nil
    
    private var activeLoaders: [AdLoader] = []
    private var fallbackLoaders: [AdLoader] = []
    
    // Current ad ID being loaded (for logging)
    private var defaultAdId = Configs.AdvertisementID.ADSNativeAdsNoMediaViewID
    private var currentAdId: Configs.AdvertisementID = .ADSNativeAdsNoMediaViewID

    private let numberOfAdsDefault: Int
    private var numberOfAdsNeeded: Int

    private var fallbackNativeAds: [NativeAd] = [] /// only use for backup case, no reload
    private var nativeAds: [NativeAd] = []

    private let nativeAdsRelay = BehaviorRelay<[NativeAd]>(value: [])
    private let bag = DisposeBag()
    
    init(numberOfAdsToLoad: Int, nativeAdId: Configs.AdvertisementID? = nil) {
        self.numberOfAdsDefault = numberOfAdsToLoad
        self.numberOfAdsNeeded = numberOfAdsToLoad
        super.init()
        guard Configs.Advertisement.canRequestAndShowAds, !IAPHelper.shared().isSubscribed() else { return }
        print("[ListNativeAdHandler] startFallbackPreload")
        
        IAPHelper.shared().subscriptionSucceed() { [weak self] isPurchased in
            if isPurchased {
                self?.nativeAds.removeAll()
                self?.nativeAdsRelay.accept([])
            }
        }
    }

    deinit {
        print("[ListNativeAdHandler] deinit")
        activeLoaders.forEach { $0.delegate = nil }
        fallbackLoaders.forEach { $0.delegate = nil }
    }
    
    func loadAds(id adId: Configs.AdvertisementID, quantity: Int, completion: (([NativeAd]) -> Void)? = nil) {
        guard Configs.Advertisement.canRequestAndShowAds, !IAPHelper.shared().isSubscribed() && TrackingUsageUtils.shared.canRequestAds else {
            nativeAdsRelay.accept([])
            completion?([])
            return
        }
        print("[ListNativeAdHandler] start native list preload. Id: \(adId), quantity: \(quantity)")

        // Cancel previous active loaders
        activeLoaders.forEach { $0.delegate = nil }
        activeLoaders.removeAll()
        nativeAds.removeAll()
        
        // Store current ad ID for logging
        currentAdId = adId
        nativeAdsCallback = completion

        numberOfAdsNeeded = max(1, quantity)

        for _ in 0..<numberOfAdsNeeded {
            makeSingleLoader(adId: adId, isFallback: false).load(Request()) /// load ad
        }
    }

    func getAds() -> [NativeAd] {
        print("[ListNativeAdHandler] getAds: \(nativeAds)")
        return nativeAds
    }

    private func rootVC() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    private func makeSingleLoader(adId: Configs.AdvertisementID, isFallback: Bool) -> AdLoader {
        print("[ListNativeAdHandler] makeSingleLoader")
        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true

        let loader = AdLoader(
            adUnitID: adId.id,
            rootViewController: rootVC(),
            adTypes: [.native],
            options: [videoOptions]
        )
        loader.delegate = self

        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .loadStart,
            adId: adId
        ))

        if isFallback {
            fallbackLoaders.append(loader)
        } else {
            activeLoaders.append(loader)
        }
        return loader
    }

    // Try to finish the batch if we already met the target or no more loaders remain
    private func finalizeIfReady() {
        if activeLoaders.isEmpty { /// no active loader mean load process is finished
            if nativeAds.count < numberOfAdsNeeded, fallbackNativeAds.isEmpty {
                let need = numberOfAdsNeeded - nativeAds.count
                let take = min(need, fallbackNativeAds.count)
                nativeAds.append(contentsOf: fallbackNativeAds.prefix(take))
                print("[ListNativeAdHandler] Fallback ads used: \(take)")
            }
            let ads = (
                !Configs.Advertisement.canRequestAndShowAds || IAPHelper.shared().isSubscribed() || !TrackingUsageUtils.shared.canRequestAds
            ) ? [] : nativeAds
            nativeAdsRelay.accept(ads)
            nativeAdsCallback?(ads)
            print("[ListNativeAdHandler] Emit ads: \(ads)")
        }
    }
}

extension ListNativeAdHandler: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("[ListNativeAdHandler] didReceive native ad")
        
        // Set rootViewController early, once when ad is loaded
        // This ensures the ad has a valid rootVC before being attached to any view
        nativeAd.rootViewController = rootVC()
        
        let network = nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName
        let lineItem = nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName

        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .loadSuccess,
            adId: currentAdId,
            network: network,
            lineItem: lineItem
        ))
        
        /// Tracking ad revenue
        let adSourceName = nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
        nativeAd.paidEventHandler = {[weak self] adValue in
            guard let self = self else { return }
            EventTrackingHelper.shared.handleAdPaidEvent(
                adRevenueNetwork: adSourceName,
                adValue: adValue,
                adId: self.currentAdId,
                unit: .native
            )
        }
        nativeAd.delegate = self

        if let idx = activeLoaders.firstIndex(where: { $0 === adLoader }) {
            nativeAds.append(nativeAd)
            activeLoaders.remove(at: idx)
            if Configs.Advertisement.canRequestAndShowAds, !IAPHelper.shared().isSubscribed(), TrackingUsageUtils.shared.canRequestAds {
                nativeAdsRelay.accept(nativeAds)
            }
            finalizeIfReady()
            return
        }

        if let idx = fallbackLoaders.firstIndex(where: { $0 === adLoader }) {
            if fallbackNativeAds.count >= numberOfAdsDefault { fallbackNativeAds.removeFirst() }
            fallbackNativeAds.append(nativeAd)
            fallbackLoaders.remove(at: idx)
            print("[ListNativeAdHandler] fallbackLoaders count: \(fallbackLoaders.count)")
            return
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("[ListNativeAdHandler] didFailToReceiveAdWithError")
        
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .loadFail,
            adId: currentAdId,
            error: error.localizedDescription
        ))
        
        if let idx = activeLoaders.firstIndex(where: { $0 === adLoader }) {
            activeLoaders.remove(at: idx)
            finalizeIfReady()
            return
        }
        if let idx = fallbackLoaders.firstIndex(where: { $0 === adLoader }) {
            fallbackLoaders.remove(at: idx)
            return
        }
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        print("[ListNativeAdHandler] adLoaderDidFinishLoading")
    }
}

extension ListNativeAdHandler: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenNativeAdImpressionEvent)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .impression,
            adId: currentAdId,
            network: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenNativeAdClickKey)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .native,
            action: .click,
            adId: currentAdId,
            network: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
}
