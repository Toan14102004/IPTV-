//
//  FullScreenNativeNewView.swift
//  I-Speed-Test-Remake
//

import UIKit
import GoogleMobileAds

class FullScreenNativeNewView: UIView, NativeAdViewProtocol {

    @IBOutlet weak var nativeAdView: NativeAdView!
    @IBOutlet weak var adLabel: UIButton!
    
    var onAdLoaded: ((Bool) -> Void)?

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
            onAdLoaded?(false)
            return
        }
        
        IAPHelper.shared().subscriptionSucceed {[weak self] isPurchased in
            if isPurchased {
                self?.gone()
                self?.onAdLoaded?(false)
            }
        }
        
        let nib = UINib(nibName: "FullScreenNativeNewView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        self.isHidden = true
    }
    
    func loadAndConfig(
        adId: Configs.AdvertisementID = .ADSNativeAdsMediaViewID,
        isSuccess: ((Bool) -> Void)? = nil
    ) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            self.gone()
            isSuccess?(false)
            onAdLoaded?(false)
            return
        }
        
        AdsManager.shared.refreshNativeAd(adId) {[weak self] ad, error in
            guard let self = self, let ad = ad, error == nil else {
                self?.gone()
                isSuccess?(false)
                self?.onAdLoaded?(false)
                return
            }
            self.visible()
            self.configure(with: ad)
            isSuccess?(true)
            self.onAdLoaded?(true)
        }
    }
    
    func configure(with nativeAd: NativeAd) {
        nativeAdView.nativeAd = nil
        
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
