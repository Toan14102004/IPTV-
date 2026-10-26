//
//  OnboardAdView.swift
//  I340_IPTV
//

import SwiftUI

struct OnboardAdView: View {
    let onClose: () -> Void

    private let isEnabled = RemoteKonfig.shared.isShowNativeAdsFullScreenIntro

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            NativeAdBannerView(
                config: .init(
                    adIdNormal: .ADSNativeFullScreenID,
                    adId2F: .ADSNativeFullScreen2FID,
                    adIdMF: .ADSNativeFullScreenMFID,
                    isEnabled: isEnabled
                ),
                height: nil
            ) {
                FullScreenNativeView(frame: .zero)
            }

            if isEnabled && !IAPHelper.shared().isSubscribed() {
                closeButton
            }
        }
        .suppressesAppOpenAd()
        .onAppear { UserDefaultManager.shared().isShowNativeFull = true }
        .onDisappear { UserDefaultManager.shared().isShowNativeFull = false }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .foregroundStyle(Color.text1)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .padding(.leading, Layout.Spacing.sm)
        .padding(.top, Layout.Spacing.xl)
    }
}
