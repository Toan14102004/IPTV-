//
//  Configs+AdvertisementID.swift
//  I340_IPTV
//

import Foundation
import AdsDebugKit

extension Configs {
    enum AdvertisementID: String, CaseIterable, Codable, AdIDProvider {
        case ADSAppOpenAdsID
        case ADSBannerID
        
        // Inter
        case ADSInterstitialAdsID
        case ADSInterstitialOpenAppID
        case ADSInterstitialOpenApp2FID
        case ADSInterstitialOpenAppMFID
        case ADSInterstitialBackgroundID
        
        // Native IDs
        case ADSNativeAdsMediaViewID
        case ADSNativeAdsNoMediaViewID
        
        case ADSNativeLanguageAds2FID
        case ADSNativeLanguageAdsMFID
        case ADSNativeLanguageAdsID
        
        case ADSNativeIntroFirstID
        case ADSNativeIntroFirst2FID
        case ADSNativeIntroFirstMFID
        
        case ADSNativeIntroThirdID
        case ADSNativeIntroThird2FID
        case ADSNativeIntroThirdMFID
        
        case ADSNativeFullScreenID
        case ADSNativeFullScreen2FID
        case ADSNativeFullScreenMFID
        
        case ADSRewardedVideoAds2FID
        case ADSRewardedVideoAdsMFID
        case ADSRewardedVideoAdsID
        
        static let allCases: [AdvertisementID] = [
            .ADSAppOpenAdsID,
            .ADSBannerID,
            .ADSInterstitialAdsID,
            .ADSInterstitialOpenAppID,
            .ADSInterstitialOpenApp2FID,
            .ADSInterstitialOpenAppMFID,
            .ADSInterstitialBackgroundID,
            .ADSNativeAdsMediaViewID,
            .ADSNativeAdsNoMediaViewID,
            .ADSNativeLanguageAdsID,
            .ADSNativeLanguageAds2FID,
            .ADSNativeLanguageAdsMFID,
            .ADSNativeIntroFirstID,
            .ADSNativeIntroFirst2FID,
            .ADSNativeIntroFirstMFID,
            .ADSNativeIntroThirdID,
            .ADSNativeIntroThird2FID,
            .ADSNativeIntroThirdMFID,
            .ADSNativeFullScreenID,
            .ADSNativeFullScreen2FID,
            .ADSNativeFullScreenMFID,
            .ADSRewardedVideoAds2FID,
            .ADSRewardedVideoAdsMFID,
            .ADSRewardedVideoAdsID
        ]
        
        /// name = key in Info.plist
        var name: String { rawValue }
        
        /// Lấy giá trị string từ Info.plist/Advertisement theo key này
        var id: String { AppConfiguration.shared.adString(self) }
        /// Optional options (trả về nil nếu chuỗi rỗng)
        var idOptional: String? {
            let v = id.trimmingCharacters(in: .whitespacesAndNewlines)
            return v.isEmpty ? nil : v
        }
    }
}
