//
//  RewardedAdManager.swift
//  I340_IPTV
//
//  Created by Phan Binh on 06/12/2022.
//

import Foundation
import GoogleMobileAds
import UIKit

//final class RewardedAdManager: NSObject {
//    
//    public static let shared = RewardedAdManager()
//    
//    private var appAllowShowAds: Bool {
//        get {
//            return !IAPHelper().isSubscribed()
//        }
//    }
//    
//    private var rewardedAd: RewardedAd?
//    
//    private var loadingAlert: UIAlertController?
//    private var currentAdIndex = 0
//    private var adIds: [String] = []
//    
//    private var onShow: (() -> Void)?
//    private var onDismiss: (() -> Void)?
//    private var onFailed: (() -> Void)?
//    private var onRewarded: (() -> Void)?
//    private var onCompleted: (() -> Void)?
//    
//    private static let maxRetryCount = 5
//    
//    private var numOfLoadAds = maxRetryCount
//    
//    private var isRewarded = false
//    var isShowingAd: Bool = false
//    
//    var hasRewared: Bool {
//        return rewardedAd != nil
//    }
//    
//    public func loadRewardedAd() {
//        guard self.appAllowShowAds else { return }
//        
//        RewardedAd.load(
//            with: Configs.Advertisement.admobRewardedVideoId,
//            request: Request(),
//            completionHandler: { [self] ad, error in
//                if let error = error {
//                    print("Failed to load rewarded ad with error: \(error.localizedDescription)")
//                    return
//                }
//                numOfLoadAds = Self.maxRetryCount
//                rewardedAd = ad
//                print("Rewarded ad loaded.")
//                rewardedAd?.fullScreenContentDelegate = self
//                
////                let adSourceName = ad?.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "admob"
////                ad?.paidEventHandler = { EventTrackingHelper.shared.handleAdPaidEvent(adRevenueNetwork: adSourceName, adValue: $0) }
//            }
//        )
//    }
//    
//    public func showAd<T: UIViewController>(
//        from viewController: T,
//        onRewarded: @escaping () -> Void,
//        onCompleted: @escaping (T) -> Void,
//        onFailed: (() -> Void)? = nil
//    ) {
//        self.onCompleted = { [weak viewController] in
//            viewController.map(onCompleted)
//            ()
//        }
//        
//        if self.appAllowShowAds, let rewardedAd = self.rewardedAd {
//            self.isShowingAd = true
//            rewardedAd.present(from: viewController) {
//                self.isRewarded = true
//                onRewarded()
//            }
//        } else {
//            onFailed?()
//        }
//    }
//}
//
//// MARK: - Load 3 floor id
//
//extension RewardedAdManager {
//    
//    func showRewardedAdMulti(
//        from viewController: UIViewController,
//        adUnitIds: [String],
//        onShow: (() -> Void)? = nil,
//        onDismiss: (() -> Void)? = nil,
//        onFailed: (() -> Void)? = nil,
//        onRewarded: (() -> Void)? = nil
//    ) {
//        guard appAllowShowAds else {
//            onFailed?()
//            return
//        }
//        
//        self.adIds = adUnitIds
//        self.currentAdIndex = 0
//        self.onShow = onShow
//        self.onDismiss = onDismiss
//        self.onFailed = onFailed
//        self.onRewarded = onRewarded
//        self.isRewarded = false
//        self.isShowingAd = false
//        
//        showLoading(in: viewController)
//        tryLoadNextAdSequentially(from: viewController)
//    }
//    
//    private func tryLoadNextAdSequentially(from viewController: UIViewController) {
//        guard currentAdIndex < adIds.count else {
//            print("### ❗️All ads tried, none loaded successfully.")
//            hideLoading()
//            onFailed?()
//            return
//        }
//        
//        let adId = adIds[currentAdIndex]
//        var didFinish = false
//        print("### ⏳ Attempting to load rewarded ad [index: \(currentAdIndex)] id: \(adId)")
//        
//        let timeoutTask = DispatchWorkItem { [weak self] in
//            guard let self = self else { return }
//            if !didFinish {
//                print("### ⏰ Timeout loading ad [index: \(self.currentAdIndex)] id: \(adId)")
//                self.currentAdIndex += 1
//                self.tryLoadNextAdSequentially(from: viewController)
//            }
//        }
//       
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeoutTask)
//        
//        RewardedAd.load(with: adId, request: Request()) { [weak self] ad, error in
//            guard let self = self else { return }
//            timeoutTask.cancel()
//            
//            guard !didFinish else { return }
//            didFinish = true
//            
//            if let ad = ad {
//                print("### ✅ Successfully loaded ad [index: \(self.currentAdIndex)] id: \(adId)")
//                self.hideLoading {
//                    self.showAd(ad, from: viewController, adId: adId)
//                }
//            } else if let error = error {
//                print("### ❌ Failed to load ad [index: \(self.currentAdIndex)] id: \(adId), error: \(error.localizedDescription)")
//                self.currentAdIndex += 1
//                self.tryLoadNextAdSequentially(from: viewController)
//            }
//        }
//    }
//    
//    private func showAd(_ ad: RewardedAd, from viewController: UIViewController, adId: String) {
//        guard !isShowingAd else { return }
//        isShowingAd = true
//        rewardedAd = ad
//        
//        ad.fullScreenContentDelegate = self
//        print("Showing rewarded ad: \(adId)")
//        
//        ad.present(from: viewController) { [weak self] in
//            guard let self = self else { return }
//            self.isRewarded = true
//            self.onRewarded?()
//        }
//        
//        onShow?()
//    }
//    
//    private func showLoading(in viewController: UIViewController) {
//        hideLoading()
//        let alert = UIAlertController(title: nil, message: "loading_ads".localized, preferredStyle: .alert)
//        viewController.present(alert, animated: true)
//        loadingAlert = alert
//    }
//
//    private func hideLoading(completion: (() -> Void)? = nil) {
//        guard let alert = loadingAlert else {
//            completion?()
//            return
//        }
//        alert.dismiss(animated: true) {
//            self.loadingAlert = nil
//            completion?()
//        }
//    }
//}
//
//extension RewardedAdManager : FullScreenContentDelegate {
//    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
//        print("Ad did fail to present full screen content. \(error.localizedDescription)")
//        
//        isShowingAd = false
//        rewardedAd = nil
//    }
//    
//    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("Ad will present full screen content.")
//    }
//    
//    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("Ad did dismiss full screen content.")
//        onCompleted?()
//        isShowingAd = false
//        rewardedAd = nil
//        onCompleted = nil
//        onDismiss?()
//    }
//}
