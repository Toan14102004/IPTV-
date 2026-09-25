//
//  UIViewController+BannerAd.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import Foundation
import GoogleMobileAds
import AdsDebugKit

extension UIViewController {
    static let TagLoadingView: Int = 9999

    func removeBannerView(_ bannerView: BannerView, topView: UIView) {
        removeBannerView(bannerView, topViews: [topView])
    }
    
    func removeBannerView(_ bannerView: BannerView, topViews: [UIView] = []) {
        bannerView.gone()
        
        topViews.forEach { topView in
            if let supper = topView.superview {
                supper.constraints.forEach { const in
                    if (const.firstAnchor == topView.bottomAnchor) {
                        const.isActive = false
                    }
                }
                topView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
            }
        }
    }
    
    func addAdmobBanner(to bannerView: BannerView) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            bannerView.gone()
            return
        }
        
        addLoadingView(bannerView: bannerView)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .banner,
            action: .loadStart,
            adId: Configs.AdvertisementID.ADSBannerID
        ))
        
        bannerView.backgroundColor = .clear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            bannerView.adUnitID = Configs.AdvertisementID.ADSBannerID.id
            bannerView.rootViewController = self
            bannerView.delegate = self
            bannerView.load(Request())
        })
    }
    
    private func addLoadingView(bannerView: UIView) {
        let loadingView = UIView().apply {
            $0.tag = UIViewController.TagLoadingView
            let loadingLabel = UILabel().apply {
                $0.text = "loading_ads".localized + "..."
                $0.textColor = .white
                $0.textAlignment = .center
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            
            // Create the activity indicator
            let activityIndicator = UIActivityIndicatorView(style: .large).apply {
                $0.startAnimating()
                $0.translatesAutoresizingMaskIntoConstraints = false
                $0.color = .white
            }
            
            $0.backgroundColor = .clear
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.addSubview(loadingLabel)
            $0.addSubview(activityIndicator)
            
            NSLayoutConstraint.activate([
                activityIndicator.trailingAnchor.constraint(equalTo: loadingLabel.leadingAnchor, constant: -10),
                activityIndicator.centerYAnchor.constraint(equalTo: $0.centerYAnchor),
                
                loadingLabel.centerYAnchor.constraint(equalTo: $0.centerYAnchor),
                loadingLabel.centerXAnchor.constraint(equalTo: $0.centerXAnchor)
            ])
        }
        
        bannerView.addSubview(loadingView)
        NSLayoutConstraint.activate([
            // Make loadingView fill the bannerView
            loadingView.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: bannerView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor),
        ])
    }
    
    func getSmartBannerSize() -> AdSize {
        let frame = { () -> CGRect in
            // Here safe area is taken into account, hence the view frame is used
            // after the view has been laid out.
            if #available(iOS 11.0, *) {
                return view.frame.inset(by: view.safeAreaInsets)
            } else {
                return view.frame
            }
        }()
        let viewWidth = frame.size.width
        
        // Step 3 - Get Adaptive GADAdSize and set the ad view.
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        return currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
    }
}

extension UIViewController: BannerViewDelegate {
    
    public func bannerViewDidRecordClick(_ bannerView: BannerView) {
        EventTrackingHelper.shared.logEventAdjustWithKey(.adjustTokenBannerAdClick)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .banner,
            action: .click,
            adId: Configs.AdvertisementID.ADSBannerID,
            network: bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    public func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        EventTrackingHelper.shared.logEventAdjustWithKey(DefaultConfigToken.adjustTokenBannerAdImpressionEvent)
        
        AdTelemetry.shared.log(AdEvent(
            unit: .banner,
            action: .impression,
            adId: Configs.AdvertisementID.ADSBannerID,
            network: bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceName,
            lineItem: bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceInstanceName
        ))
    }
    
    public func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        AdTelemetry.shared.log(AdEvent(
            unit: .banner,
            action: .loadFail,
            adId: Configs.AdvertisementID.ADSBannerID,
            error: error.localizedDescription
        ))
    }
    
    public func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        bannerView.subviews.forEach {
            if $0.tag == UIViewController.TagLoadingView {
                $0.removeFromSuperview()
            }
        }
        
        let network = bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceName
        let lineItem = bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceInstanceName
        
        AdTelemetry.shared.log(AdEvent(
            unit: .banner,
            action: .loadSuccess,
            adId: Configs.AdvertisementID.ADSBannerID,
            network: network,
            lineItem: lineItem
        ))
        
        /// Tracking ad revenue
        let adSourceName = bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adSourceName ?? "unknown_source"
        bannerView.paidEventHandler = { adValue in
            EventTrackingHelper.shared.handleAdPaidEvent(
                adRevenueNetwork: adSourceName,
                adValue: adValue,
                adId: Configs.AdvertisementID.ADSBannerID,
                unit: .banner
            )
        }
    }
}
