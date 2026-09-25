//
//  OnboardPageView.swift
//  I340_IPTV
//

import SwiftUI

/// One intro page: artwork, title, subtitle, page indicator, Next button and a native ad.
struct OnboardPageView: View {
    let item: OnboardItem
    let index: Int
    let onNext: () -> Void

    /// The first page makes the user wait a moment before Next appears.
    @State private var isNextEnabled: Bool

    init(item: OnboardItem, index: Int, onNext: @escaping () -> Void) {
        self.item = item
        self.index = index
        self.onNext = onNext
        _isNextEnabled = State(initialValue: index != 0)
    }

    var body: some View {
        // The artwork is a background so that it does not extend the layout under the home indicator.
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Text(item.title.uppercased())
                .font(FontFamily.UTMBebas.regular.font(size: 40))
                .foregroundStyle(Asset.Color.colorPrimaryLegacy.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.m)

            Text(item.subTitle)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.s)

            pageControlRow
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.s)

            if isNativeAdEnabled {
                NativeAdBannerView(config: adConfig, height: 273) {
                    LargeNativeAdViewOnboard(frame: .zero)
                }
                .padding(.top, Layout.Spacing.l)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .task { await enableNextAfterDelayIfNeeded() }
    }
}

// MARK: - Subviews

private extension OnboardPageView {
    @ViewBuilder
    var background: some View {
        // Small screens stretch the artwork instead of cropping it.
        Group {
            if UIScreen.main.bounds.height < 812 {
                Image(item.image).resizable()
            } else {
                Image(item.image).resizable().scaledToFill()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    var pageControlRow: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Image(item.pageControlImage)
                .resizable()
                .scaledToFit()
                .frame(width: 66, height: 8)

            Spacer(minLength: 0)

            ZStack {
                Button(action: onNext) {
                    Text("next".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Asset.Color.colorPrimaryLegacy.color)
                        .frame(width: 112, height: 31, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .opacity(isNextEnabled ? 1 : 0)
                .disabled(!isNextEnabled)

                if !isNextEnabled {
                    ProgressView()
                        .tint(Asset.Color.colorPrimaryLegacy.color)
                }
            }
            .frame(width: 112, height: 31)
        }
    }
}

// MARK: - Logic

private extension OnboardPageView {
    /// No ad on the second page, otherwise controlled by remote config.
    var isNativeAdEnabled: Bool {
        index != 1
            && RemoteKonfig.shared.isShowAdIntro
            && Configs.Advertisement.canRequestAndShowAds
            && !IAPHelper.shared().isSubscribed()
    }

    var adConfig: NativeAdController.Config {
        switch index {
        case 0:
            return .init(adIdNormal: .ADSNativeIntroFirstID, adId2F: .ADSNativeIntroFirst2FID, adIdMF: .ADSNativeIntroFirstMFID)
        case 2:
            return .init(adIdNormal: .ADSNativeIntroThirdID, adId2F: .ADSNativeIntroThird2FID, adIdMF: .ADSNativeIntroThirdMFID)
        default:
            return .init(adIdNormal: .ADSNativeAdsMediaViewID)
        }
    }

    func enableNextAfterDelayIfNeeded() async {
        guard !isNextEnabled else { return }
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        withAnimation { isNextEnabled = true }
    }
}
