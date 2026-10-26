//
//  SettingsView.swift
//  I340_IPTV
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: ViewModel

    /// `onBack` is nil for the Settings tab, which shows no back button.
    init(onBack: (() -> Void)?) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.white) {
            VStack(spacing: 0) {
                ScreenHeader(title: viewModel.screenTitle, onBack: viewModel.backAction)

                ScrollView {
                    VStack(spacing: Layout.Spacing.m) {
                        NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                            MediumNativeAdView(frame: .zero)
                        }

                        VStack(spacing: Layout.Spacing.m) {
                            if !viewModel.isSubscribed {
                                premiumBanner
                            }

                            optionsCard
                        }
                        .padding(.horizontal, Layout.Spacing.m)
                    }
                    .padding(.bottom, Layout.Spacing.m)
                }
            }
        }
        .toast(message: $viewModel.toast)
        .trackScreen("Settings")
        .popup(item: $viewModel.coordinator.alert) { _ in
            ConfirmDialogView(
                title: "settings_clear_cache".localized(fallback: "Clear cache"),
                message: "settings_clear_cache_message".localized(
                    fallback: "Downloaded images and temporary data will be removed. Your playlists are kept."
                ),
                noTitle: "playlist_delete_no".localized(fallback: "No"),
                yesTitle: "playlist_delete_yes".localized(fallback: "Yes"),
                onNo: viewModel.dismissAlert,
                onYes: viewModel.confirmClearCache
            )
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }
}

// MARK: - Subviews

private extension SettingsView {
    var premiumBanner: some View {
        Button(action: viewModel.didTapPremium) {
            VStack(alignment: .leading, spacing: Layout.Spacing.sm) {
                VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                    HStack(spacing: Layout.Spacing.xs) {
                        Text(viewModel.premiumTitle)
                            .font(FontFamily.Poppins.bold.font(size: 20))
                        Asset.Icon.icCrown.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    Text(viewModel.premiumMessage)
                        .font(Typography.bodySmall)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                HStack(spacing: Layout.Spacing.xs) {
                    Text(viewModel.upgradeTitle)
                        .font(Typography.labelMedium)
                    Asset.Icon.icArrowRight.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .padding(.horizontal, Layout.Spacing.sm)
                .padding(.vertical, Layout.Spacing.xs)
                .background(LinearGradient.primaryLinear, in: Capsule())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 200, alignment: .leading)
            .padding(.horizontal, Layout.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 130)
            .background(
                Asset.Image.imgSettingsPremiumBanner.image
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
            .contentShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }

    var optionsCard: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.options) { option in
                SettingRow(
                    icon: option.icon,
                    tint: option.tint,
                    title: viewModel.title(for: option),
                    showsDivider: option != viewModel.options.last
                ) {
                    viewModel.didSelect(option)
                }
            }
        }
        .padding(.horizontal, Layout.Spacing.m)
        .background(Color.background1, in: RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
    }
}

// MARK: - Row

private struct SettingRow: View {
    let icon: ImageAsset
    let tint: Color
    let title: String
    var showsDivider = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.Spacing.s) {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .frame(width: 28, height: 28)
                    .background(tint, in: RoundedRectangle(cornerRadius: 4))

                Text(title)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Asset.Icon.icSettingsChevron.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.text3)
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, Layout.Spacing.m)
            .frame(minHeight: 60)
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Color.neutral1.frame(height: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(onBack: {})
        .preview()
}
