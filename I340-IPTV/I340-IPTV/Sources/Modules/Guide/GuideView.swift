//
//  GuideView.swift
//  I340_IPTV
//

import SwiftUI

/// "How to use" guide: three steps explained with screenshots.
struct GuideView: View {
    @StateObject private var viewModel: ViewModel

    init(onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        BaseView(background: Asset.Color.screenBackgroundDark.color) {
            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        stepOne
                        stepTwo
                        stepThree

                        bodyText("guide_final_note")
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                }
                .padding(.top, Layout.Spacing.m)

                NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                    MediumNativeAdView(frame: .zero)
                }
            }
        }
    }
}

// MARK: - Sections

private extension GuideView {
    var header: some View {
        HStack(spacing: Layout.Spacing.s) {
            BackButton(tint: Asset.Color.lavender.color, size: 24, action: viewModel.didTapBack)
                .frame(width: 36, height: 36)

            Text("guide_title".localized)
                .font(FontFamily.Poppins.medium.font(size: 20))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.leading, Layout.Spacing.m)
        .padding(.top, 11)
    }

    var stepOne: some View {
        StepRow(pill: viewModel.stepTitle(1), bottomSpacing: 24) {
            stepTitle("guide_step_1_title")
            bodyText("guide_step_1_body")
            HStack(spacing: Layout.Spacing.sm) {
                GuideImage(image: Asset.Image.Guide.icGuideStep11, width: 84, height: 191)
                    .frame(maxWidth: .infinity, alignment: .leading)
                GuideImage(image: Asset.Image.Guide.icGuideStep12, width: 84, height: 191)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var stepTwo: some View {
        StepRow(pill: viewModel.stepTitle(2), bottomSpacing: 24) {
            stepTitle("guide_step_2_title")
            bodyText("guide_step_2_body")
        }
    }

    var stepThree: some View {
        StepRow(pill: viewModel.stepTitle(3), bottomSpacing: 42) {
            stepTitle("guide_step_3_title")
            bodyText("guide_step_3_intro")
            GuideImage(image: Asset.Image.Guide.icGuideStep31, width: 122, height: 277)
            bodyText("guide_step_3_xtream")
            GuideImage(image: Asset.Image.Guide.icGuideStep32, width: 122, height: 277)
            bodyText("guide_step_3_file")
            GuideImage(image: Asset.Image.Guide.icGuideStep33, width: 122, height: 277)
            bodyText("guide_step_3_stream")
            GuideImage(image: Asset.Image.Guide.icGuideStep34, width: 122, height: 277)
        }
    }

    func stepTitle(_ key: String) -> some View {
        Text(key.localized)
            .font(FontFamily.Poppins.medium.font(size: 14))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func bodyText(_ key: String) -> some View {
        Text(key.localized)
            .font(FontFamily.Poppins.regular.font(size: 13))
            .foregroundColor(Asset.Color.textMuted.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Components

/// A step: pill + dashed timeline on the left, content on the right.
private struct StepRow<Content: View>: View {
    let pill: String
    let bottomSpacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: Layout.Spacing.sm) {
            VStack(spacing: 5) {
                Text(pill)
                    .font(FontFamily.Poppins.medium.font(size: 11))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 22)
                    .background(
                        LinearGradient(
                            colors: [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color, Asset.Color.brandRedDark.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Asset.Color.pinkBorder.color, lineWidth: 1))

                DashedLine()
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 70)
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 10) {
                content
                Color.clear.frame(height: bottomSpacing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DashedLine: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
            }
            .stroke(Asset.Color.textDisabled.color, style: StrokeStyle(lineWidth: 2, dash: [3, 5]))
        }
    }
}

private struct GuideImage: View {
    let image: ImageAsset
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        image.image
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .background(Asset.Color.blackSoft.color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Asset.Color.fieldBackground.color, lineWidth: 1))
    }
}

#Preview {
    GuideView(onBack: {})
        .preview()
}
