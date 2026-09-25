//
//  CustomSlideNativeView.swift
//  ios-blockspam
//
//  Created by Kietkoy on 17/3/26.
//  Copyright © 2026 FoxCode. All rights reserved.
//


import UIKit
import GoogleMobileAds

class CustomSlideNativeView:  UIView, NativeAdViewProtocol {
    @IBOutlet weak var nativeAdView: NativeAdView!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        let nib = UINib(nibName: "CustomSlideNativeView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return }
        view.frame = self.bounds
        nativeAdView.callToActionView?.isHidden = true
        addSubview(view)
    }
    
    func loadAndConfig(adId: Configs.AdvertisementID = .ADSNativeAdsMediaViewID,
                       isSuccess: ((Bool) -> Void)? = nil) {
        self.gone()
        AdsManager.shared.refreshNativeAd(adId) {[weak self] ad, error in
            guard let self = self, let ad = ad, error == nil else {
                self?.gone()
                isSuccess?(false)
                return
            }
            self.visible()
            self.configure(with: ad)
            isSuccess?(true)
        }
    }
    
    func configure(with nativeAd: NativeAd) {
        
        nativeAdView.nativeAd = nativeAd
        
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
    }
}
