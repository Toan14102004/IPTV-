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

    /// Native ad of the language screen (2F → MF → normal priority).
    private var adConfig: NativeAdController.Config {
        NativeAdController.Config(
            adIdNormal: Configs.AdvertisementID.ADSNativeLanguageAdsID,
            adId2F: Configs.AdvertisementID.ADSNativeLanguageAds2FID,
            adIdMF: Configs.AdvertisementID.ADSNativeLanguageAdsMFID,
            isEnabled: RemoteKonfig.shared.isShowAdLanguage
        )
    }

    var body: some View {
        BaseView {
            VStack(spacing: 0) {
                header

                ZStack(alignment: .topTrailing) {
                    languageList
                    if !viewModel.isTooltipHidden {
                        Asset.Icon.icGuide.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 153, height: 62)
                            .padding(.top, 35)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, Layout.Spacing.s)
                .padding(.top, Layout.Spacing.sm)

                NativeAdBannerView(config: adConfig, height: 262) {
                    LargeNativeAdViewOnboard(frame: .zero)
                }
            }
        }
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case .restartRequired:
                CustomAlertView(
                    title: LocalizedStringKey("notification".localized),
                    description: LocalizedStringKey("needs_to_be_restarted_to_change_language".localized),
                    cancelActionTitle: LocalizedStringKey("cancel".localized),
                    cancelAction: viewModel.cancelRestart,
                    primaryActionTitle: LocalizedStringKey("yes".localized),
                    primaryActionTitleColor: .white,
                    primaryAction: viewModel.confirmRestart
                )
            }
        } customize: { params in
            params.centerPopup()
        }
    }
}

// MARK: - Subviews

private extension LanguageView {
    var header: some View {
        HStack(spacing: Layout.Spacing.m) {
            // The back button only exists when opened from Settings, but keeps its space.
            Button(action: viewModel.didTapBack) {
                Asset.Icon.icArrowLeft.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
            }
            .opacity(viewModel.isOpenApp ? 0 : 1)
            .disabled(viewModel.isOpenApp)

            Text("choose_the_language".localized)
                .font(FontFamily.Cabin.bold.font(size: 20))
                .foregroundStyle(Asset.Color.colorWhite.color)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: viewModel.didTapDone) {
                Asset.Icon.icChecked.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, Layout.Spacing.l)
        .frame(height: 44)
    }

    var languageList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.Spacing.sm) {
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
        HStack(spacing: Layout.Spacing.s) {
            Image(language.imgFlag)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.small))

            Text(language.lbCountry)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: titleAlignment)

            (language.isSelected ? Asset.Icon.icCheckedLg : Asset.Icon.icUncheck).image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, Layout.Spacing.sm)
        .frame(height: 56)
        .background(Asset.Color.fieldBackground.color, in: RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
        .contentShape(Rectangle())
    }

    /// Arabic is always right-aligned, every other language left-aligned (physical sides).
    private var titleAlignment: Alignment {
        let wantsRight = language.languageCode.code == LanguageCode.arabic.code
        return wantsRight == (layoutDirection == .leftToRight) ? .trailing : .leading
    }
}

#Preview {
    LanguageView(context: .onboarding)
        .preview()
}
