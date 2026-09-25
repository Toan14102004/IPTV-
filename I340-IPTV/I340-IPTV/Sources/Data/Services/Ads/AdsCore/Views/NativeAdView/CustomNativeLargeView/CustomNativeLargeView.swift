//
//  CustomNativeLargeView.swift
//  I-Speed-Test-Remake
//

import UIKit
import GoogleMobileAds

class CustomNativeLargeView: UIView, NativeAdViewProtocol {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nativeAdView: NativeAdView!
    @IBOutlet weak var adLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    private func setupView() {
        if !Configs.Advertisement.canRequestAndShowAds || IAPHelper.shared().isSubscribed() {
            self.gone()
            return
        }
        
        IAPHelper.shared().subscriptionSucceed {[weak self] isPurchased in
            if isPurchased {
                self?.gone()
            }
        }
        
        Bundle.main.loadNibNamed("CustomNativeLargeView", owner: self)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        adLabel.roundDifferentCorners(bottomRight: 6)
        
        self.isHidden = true
    }
    
    func loadAndConfig(adId: Configs.AdvertisementID = .ADSNativeAdsMediaViewID,
                isSuccess: ((Bool) -> Void)? = nil) {
        
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
    
    func setLoadingState() {
        (nativeAdView.headlineView as? UILabel)?.text = ""
        (nativeAdView.bodyView as? UILabel)?.text = ""
        (nativeAdView.iconView as? UIImageView)?.image = nil
        nativeAdView.mediaView?.mediaContent = nil
        nativeAdView.callToActionView?.isHidden = true
        adLabel.isHidden = true
    }
    
    func configure(with nativeAd: NativeAd) {
        nativeAdView.nativeAd = nil
        
        adLabel.isHidden = false
        nativeAdView.nativeAd = nativeAd
        
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.iconView as? UIImageView)?.backgroundColor = .darkGray
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
    }
}
