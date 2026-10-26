//
//  LanguageView.swift
//  I340_IPTV
//

import SwiftUI

struct LanguageView: View {
    @StateObject private var viewModel: ViewModel

    init(context: Context) {
        _viewModel = StateObject(wrappedValue: ViewModel(context: context))
    }

    private var adConfig: NativeAdController.Config {
        NativeAdController.Config(
            adIdNormal: Configs.AdvertisementID.ADSNativeLanguageAdsID,
            adId2F: Configs.AdvertisementID.ADSNativeLanguageAds2FID,
            adIdMF: Configs.AdvertisementID.ADSNativeLanguageAdsMFID,
            isEnabled: RemoteKonfig.shared.isShowAdLanguage
        )
    }

    var body: some View {
        BaseView(background: Color.white) {
            VStack(spacing: 0) {
                header

                ZStack(alignment: .topTrailing) {
                    languageList

                    if !viewModel.isTooltipHidden {
                        ChooseLanguageTooltip()
                            .padding(.top, 21)
                            .padding(.trailing, 3)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.s)

                NativeAdBannerView(config: adConfig, height: 261) {
                    LargeNativeAdViewOnboard(frame: .zero)
                }
            }
        }
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case .restartRequired:
                AppDialogView(
                    title: "notification".localized,
                    message: "needs_to_be_restarted_to_change_language".localized,
                    secondaryTitle: "cancel".localized,
                    primaryTitle: "yes".localized,
                    onSecondary: viewModel.cancelRestart,
                    onPrimary: viewModel.confirmRestart,
                    secondaryColor: Color.text2,
                    primaryColor: Color.primary1
                )
            }
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }
}

// MARK: - Subviews

private extension LanguageView {
    var header: some View {
        HStack(spacing: Layout.Spacing.s) {
            // The back button only exists when opened from Settings.
            if !viewModel.isOpenApp {
                Button(action: viewModel.didTapBack) {
                    Asset.Icon.icArrowLeft.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.text1)
                        .frame(width: 32, height: 44, alignment: .leading)
                }
            }

            Text("settings_language".localized)
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: viewModel.didTapDone) {
                Asset.Icon.icChecked.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(viewModel.hasSelection ? Color.primary1 : Color.neutral1)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
        }
        .padding(.horizontal, Layout.Spacing.m)
        .frame(height: 56)
    }

    var languageList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.Spacing.s) {
                ForEach(viewModel.languages) { language in
                    LanguageRow(language: language)
                        .onTapGesture { viewModel.select(language) }
                }
            }
        }
    }
}

// MARK: - Row

private struct LanguageRow: View {
    @Environment(\.layoutDirection) private var layoutDirection

    let language: Language

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Image(language.imgFlag)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.xs))

            Text(language.lbCountry)
                .font(Typography.bodyMedium)
                .foregroundStyle(language.isSelected ? Color.primary1 : Color.text1)
                .frame(maxWidth: .infinity, alignment: titleAlignment)

            RadioIndicator(isSelected: language.isSelected)
        }
        .padding(.horizontal, Layout.Spacing.m)
        .frame(height: 48)
        .background(
            language.isSelected ? Color.surface2 : Color.white,
            in: RoundedRectangle(cornerRadius: Layout.CornerRadius.medium)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.CornerRadius.medium)
                .strokeBorder(language.isSelected ? Color.primary1 : Color.border1, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    /// Arabic is always right-aligned, every other language left-aligned (physical sides).
    private var titleAlignment: Alignment {
        let wantsRight = language.languageCode.code == LanguageCode.arabic.code
        return wantsRight == (layoutDirection == .leftToRight) ? .trailing : .leading
    }
}

private struct RadioIndicator: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .strokeBorder(isSelected ? Color.primary1 : Color.neutral1, lineWidth: 1)
            .overlay {
                if isSelected {
                    Circle()
                        .fill(Color.primary1)
                        .frame(width: 10, height: 10)
                }
            }
            .frame(width: 16, height: 16)
    }
}

// MARK: - Tooltip

private struct ChooseLanguageTooltip: View {
    var body: some View {
        HStack(spacing: Layout.Spacing.xs) {
            HStack(spacing: 0) {
                Text("choose_the_language".localized)
                    .font(Typography.captionMedium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, Layout.Spacing.sm)
                    .frame(height: 32)
                    .background(Color.primary1, in: RoundedRectangle(cornerRadius: Layout.CornerRadius.medium))

                RightPointer()
                    .fill(Color.primary1)
                    .frame(width: 6, height: 12)
            }

            Asset.Icon.icFinger.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.primary1)
                .frame(width: 32, height: 32)
        }
    }
}

private struct RightPointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

#Preview {
    LanguageView(context: .onboarding)
        .preview()
}
