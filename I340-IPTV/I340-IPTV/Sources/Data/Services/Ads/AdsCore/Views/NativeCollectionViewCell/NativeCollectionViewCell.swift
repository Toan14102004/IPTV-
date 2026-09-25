//
//  NativeCollectionViewCell.swift
//  I340_IPTV
//
//  Created by Phan Binh on 17/06/2022.
//

import UIKit
import GoogleMobileAds
import Kingfisher

class NativeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var nativeAdView: NativeAdView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with nativeAd: NativeAd) {
        nativeAdView.nativeAd = nativeAd
        nativeAdView.mediaView?.mediaContent = nil
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.headlineView as? UILabel)?.textColor = UIColor(named: "color_white") ?? .white
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        (nativeAdView.bodyView as? UILabel)?.textColor = UIColor(named: "color_secondary")
        
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
        (nativeAdView.advertiserView as? UILabel)?.textColor = UIColor(named: "color_secondary")
        
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
    }
    
}
