//
//  GuideView.swift
//  I340_IPTV
//

import SwiftUI

struct GuideView: View {
    @StateObject private var viewModel: ViewModel

    init(onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: "guide_how_to_use".localized(fallback: "How to use"),
                    onBack: viewModel.didTapBack,
                    onPremium: viewModel.premiumAction
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Layout.Spacing.sm) {
                        GuideStepCard(
                            step: viewModel.stepTitle(1),
                            title: "guide_step_1_heading".localized(fallback: "Open Add Playlist"),
                            message: "guide_step_1_message".localized(
                                fallback: "Tap the “+” button on the screen to get started"
                            ),
                            image: Asset.Image.imgGuideStep1
                        )
                        GuideStepCard(
                            step: viewModel.stepTitle(2),
                            title: "guide_step_2_heading".localized(fallback: "Choose Import Method"),
                            message: "guide_step_2_message".localized(
                                fallback: "Select how you'd like to add your playlist"
                            ),
                            image: Asset.Image.imgGuideStep2
                        )
                        GuideStepCard(
                            step: viewModel.stepTitle(3),
                            title: "guide_step_3_heading".localized(fallback: "Enter Playlist Details"),
                            message: "guide_step_3_message".localized(
                                fallback: "Enter a name and provide your source link or upload a file to complete setup"
                            ),
                            image: nil
                        )
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                    .padding(.bottom, Layout.Spacing.m)
                }

                NativeAdBannerView(
                    config: .init(adIdNormal: .ADSNativeAdsNoMediaViewID),
                    height: ExtraSmallNativeAdView.height
                ) {
                    ExtraSmallNativeAdView(frame: .zero)
                }
            }
        }
        .trackScreen("Guide")
    }
}

// MARK: - Step card

private struct GuideStepCard: View {
    let step: String
    let title: String
    let message: String
    let image: ImageAsset?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.l) {
            VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                HStack(alignment: .top, spacing: Layout.Spacing.s) {
                    Text(title)
                        .font(Typography.labelMedium)
                        .foregroundStyle(Color.text1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(step)
                        .font(Typography.labelMedium)
                        .foregroundStyle(Color.text4)
                        .lineLimit(1)
                        .padding(.horizontal, Layout.Spacing.s)
                        .frame(height: 20)
                        .background(Color.accent3, in: Capsule())
                }

                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let image {
                // The exported artwork carries an 8pt shadow bleed on every side.
                image.image
                    .resizable()
                    .scaledToFit()
                    .padding(-8)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Layout.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface1, in: RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.CornerRadius.large)
                .strokeBorder(Color.neutralStroke, lineWidth: 1)
        )
    }
}

#Preview {
    GuideView(onBack: {})
        .preview()
}
