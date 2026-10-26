//
//  XtreamContentView.swift
//  I340_IPTV
//

import Combine
import SwiftUI

/// Content of an opened Xtream profile: premium banner and one carousel per category.
struct XtreamContentView: View {
    @ObservedObject var viewModel: ViewModel
    @State private var bannerIndex = 0

    private let bannerTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: viewModel.profileName,
                onBack: viewModel.didTapBack,
                onPremium: viewModel.premiumAction
            )

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: viewModel.refreshFavorites)
    }
}

// MARK: - Content

private extension XtreamContentView {
    @ViewBuilder
    var content: some View {
        if let text = viewModel.placeholderText {
            Text(text)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.m)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Layout.Spacing.m) {
                    if viewModel.premiumAction != nil {
                        premiumBanner
                            .padding(.horizontal, Layout.Spacing.m)
                    }

                    ForEach(Array(viewModel.sections.enumerated()), id: \.element.id) { index, section in
                        sectionView(section)

                        if index == 0, !viewModel.isSubscribed {
                            NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                                MediumNativeAdView(frame: .zero)
                            }
                        }
                    }
                }
                .padding(.vertical, Layout.Spacing.xs)
                .padding(.bottom, Layout.Spacing.l)
            }
        }
    }

    /// Three promo slides (Figma "Slider"): swipe, or wait for the next one.
    var premiumBanner: some View {
        TabView(selection: $bannerIndex) {
            ForEach(Array(XtreamBannerSlide.all.enumerated()), id: \.offset) { index, slide in
                bannerSlide(slide).tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 240)
        .overlay(alignment: .bottom) { bannerDots }
        .onReceive(bannerTimer) { _ in
            withAnimation { bannerIndex = (bannerIndex + 1) % XtreamBannerSlide.all.count }
        }
    }

    func bannerSlide(_ slide: XtreamBannerSlide) -> some View {
        Button { AppNavigator.presentPaywall() } label: {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                // The design uses Recoleta Alt, which the project does not ship; New York is the agreed stand-in.
                Text(slide.title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                Text(slide.message)
                    .font(Typography.labelSmall)
                    .padding(.top, Layout.Spacing.xs)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.bottom, 36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 240)
            .overlay(alignment: .bottomTrailing) {
                Text("xtream_banner_action".localized(fallback: "Surprise"))
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Layout.Spacing.s)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2), in: Capsule())
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.trailing, Layout.Spacing.m)
                    .padding(.bottom, 42)
            }
            .background(
                ZStack {
                    slide.image.image
                        .resizable()
                        .scaledToFill()
                    // Keeps the white text readable over the bright artwork.
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0), location: 0.5),
                            .init(color: .black.opacity(0.6), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Rounded diamonds (Figma "Pagination") on a frosted capsule.
    var bannerDots: some View {
        HStack(spacing: Layout.Spacing.s) {
            ForEach(0..<XtreamBannerSlide.all.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(index == bannerIndex ? Color.primary1 : Color.primary2)
                    .frame(width: 7, height: 7)
                    .rotationEffect(.degrees(45))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal, Layout.Spacing.s)
        .padding(.vertical, Layout.Spacing.xs)
        .background(Color.black.opacity(0.2), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, Layout.Spacing.s)
        .allowsHitTesting(false)
    }

    func sectionView(_ section: XtreamSection) -> some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.s) {
            HStack(spacing: Layout.Spacing.xs) {
                Text(section.title)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)
                Asset.Icon.icPlaylistSeeAll.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.text1)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Layout.Spacing.m)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(section.channels) { channel in
                        XtreamPosterView(
                            channel: channel,
                            isFavorite: viewModel.isFavorite(channel),
                            onTap: { viewModel.open(channel, in: section.channels) },
                            onFavorite: { viewModel.toggleFavorite(channel) }
                        )
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
                // Room for the card shadow.
                .padding(.vertical, Layout.Spacing.xs)
            }
        }
    }
}

// MARK: - Banner slides

struct XtreamBannerSlide {
    let image: ImageAsset
    let title: String
    let message: String

    static var all: [XtreamBannerSlide] {
        [
            XtreamBannerSlide(
                image: Asset.Image.imgXtreamBanner,
                title: "xtream_banner_title".localized(fallback: "Go Premium"),
                message: "xtream_banner_message".localized(fallback: "Unlock more. Watch without limits.")
            ),
            XtreamBannerSlide(
                image: Asset.Image.imgXtreamBanner2,
                title: "xtream_banner2_title".localized(fallback: "Explore More"),
                message: "xtream_banner2_message".localized(fallback: "Discover channels, shows, and videos.")
            ),
            XtreamBannerSlide(
                image: Asset.Image.imgXtreamBanner3,
                title: "xtream_banner3_title".localized(fallback: "All Your Favorites"),
                message: "xtream_banner3_message".localized(fallback: "Enjoy more content in one place.")
            )
        ]
    }
}
