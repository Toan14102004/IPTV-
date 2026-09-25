//
//  SettingsView.swift
//  I340_IPTV
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: ViewModel

    init(onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        BaseView(background: Asset.Color.screenBackground.color) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    header

                    if !viewModel.isSubscribed {
                        premiumBanner
                            .padding(.top, Layout.Spacing.s)
                    }

                    optionsCard
                        .padding(.top, Layout.Spacing.l)
                }
                .padding(.horizontal, Layout.Spacing.m)

                Spacer(minLength: 0)

                NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 262) {
                    LargeNativeAdViewOnboard(frame: .zero)
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
    var header: some View {
        HStack(spacing: Layout.Spacing.xs) {
            BackButton(action: viewModel.didTapBack)
                .frame(width: 24, height: 24)

            Text(viewModel.screenTitle)
                .font(FontFamily.Poppins.medium.font(size: 24))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.leading, Layout.Spacing.s)

            Spacer(minLength: 0)
        }
        .padding(.top, Layout.Spacing.sm)
    }

    var premiumBanner: some View {
        Button(action: viewModel.didTapPremium) {
            ZStack(alignment: .leading) {
                Asset.Image.imgSettingsPremiumBanner.image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: Layout.Spacing.xxs) {
                    (
                        Text(viewModel.upgradePrefix).foregroundColor(.white)
                            + Text(viewModel.upgradePremium).foregroundColor(.brand)
                    )
                    .font(FontFamily.Poppins.bold.font(size: 18))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Text(viewModel.upgradeMessage)
                        .font(FontFamily.Poppins.regular.font(size: 12))
                        .foregroundColor(Asset.Color.textLight.color)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 204, alignment: .leading)
                .padding(.leading, Layout.Spacing.m)

                HStack {
                    Spacer()
                    Asset.Icon.icSettingsPremiumArrow.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .padding(.trailing, Layout.Spacing.m)
                }
            }
            .frame(height: 96)
            .background(Asset.Color.cardBackground.color)
            .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
            .overlay(RoundedRectangle(cornerRadius: Layout.CornerRadius.large).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }

    var optionsCard: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.options) { option in
                SettingRow(icon: option.icon, tint: option.iconTint, title: viewModel.title(for: option)) {
                    viewModel.didSelect(option)
                }
            }
        }
        .padding(Layout.Spacing.sm)
        .background(Asset.Color.cardBackground.color)
        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: Layout.CornerRadius.large).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
    }
}

// MARK: - Row

private struct SettingRow: View {
    let icon: ImageAsset
    var tint: Color?
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.Spacing.sm) {
                Group {
                    if let tint {
                        icon.image.renderingMode(.template).resizable().foregroundColor(tint)
                    } else {
                        icon.image.resizable()
                    }
                }
                .scaledToFit()
                .frame(width: 24, height: 24)

                Text(title)
                    .font(FontFamily.Poppins.regular.font(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Asset.Icon.icSettingsChevron.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Layout.Spacing.sm)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(onBack: {})
        .preview()
}
