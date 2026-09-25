//
//  NativeAdViewProtocol.swift
//  I340_IPTV
//
//  Created by Kietkoy on 4/2/26.
//

import UIKit
import GoogleMobileAds

protocol NativeAdViewProtocol: UIView {
    func loadAndConfig(adId: Configs.AdvertisementID, isSuccess: ((Bool) -> Void)?)
    func configure(with nativeAd: NativeAd)
    func cancelPendingLoad()
}

extension NativeAdViewProtocol {
    func cancelPendingLoad() {}
}
