//
//  OnboardPageView.swift
//  I340_IPTV
//

import SwiftUI

struct OnboardPageView: View {
    let item: OnboardItem
    let index: Int
    let pageCount: Int
    let onNext: () -> Void
    let onSkip: () -> Void

    /// The first page makes the user wait a moment before Next and Skip appear.
    @State private var isNextEnabled: Bool

    init(item: OnboardItem, index: Int, pageCount: Int, onNext: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.item = item
        self.index = index
        self.pageCount = pageCount
        self.onNext = onNext
        self.onSkip = onSkip
        _isNextEnabled = State(initialValue: index != 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            hero

            if isNativeAdEnabled {
                NativeAdBannerView(config: adConfig, height: 200) {
                    MediumNativeAdView(frame: .zero)
                }
                .background(Color.white.ignoresSafeArea(edges: .bottom))
            }
        }
        .task { await enableNextAfterDelayIfNeeded() }
    }
}

// MARK: - Subviews

private extension OnboardPageView {
    var hero: some View {
        VStack(spacing: isNativeAdEnabled ? Layout.Spacing.xs : Layout.Spacing.l) {
            Spacer(minLength: 0)

            VStack(spacing: Layout.Spacing.s) {
                Text(item.title)
                    .font(Typography.headlineMedium)
                    .foregroundStyle(.white)

                Text(item.subTitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Layout.Spacing.m)

            controlsRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(artwork)
        .overlay(alignment: .topTrailing) { skipButton }
    }

    var artwork: some View {
        Color.clear
            .overlay(alignment: .top) {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .ignoresSafeArea(edges: isNativeAdEnabled ? .top : .all)
    }

    var controlsRow: some View {
        HStack {
            PageIndicator(count: pageCount, current: index)

            Spacer(minLength: 0)

            ZStack {
                nextButton
                    .opacity(isNextEnabled ? 1 : 0)
                    .disabled(!isNextEnabled)

                if !isNextEnabled {
                    ProgressView()
                        .tint(Color.primary1)
                }
            }
        }
        .padding(Layout.Spacing.m)
    }

    var nextButton: some View {
        Button(action: onNext) {
            HStack(spacing: Layout.Spacing.xs) {
                Text("next".localized)
                    .font(Typography.bodyLarge)

                Asset.Icon.icArrowRight.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Layout.Spacing.sm)
            .frame(height: 28)
            .background(LinearGradient.primaryLinear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    var skipButton: some View {
        Button(action: onSkip) {
            Text("skip".localized)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.text3)
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isNextEnabled ? 1 : 0)
        .disabled(!isNextEnabled)
    }
}

// MARK: - Page indicator

private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Layout.Spacing.xs) {
            ForEach(0..<count, id: \.self) { page in
                Circle()
                    .fill(page == current ? Color.primary1 : .clear)
                    .overlay(Circle().strokeBorder(page == current ? .clear : Color.surface2, lineWidth: 1))
                    .frame(width: 10, height: 10)
            }
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
