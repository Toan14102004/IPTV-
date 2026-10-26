//
//  PaywallView.swift
//  I340_IPTV
//

import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel: ViewModel


    init(onFinish: @escaping (_ isPurchased: Bool) -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onFinish: onFinish))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

            hero

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Keeps the hero artwork visible above the content on tall screens.
                        Spacer(minLength: 240)
                        content
                    }
                    .frame(minHeight: proxy.size.height)
                }
            }

            closeButton

            if viewModel.isBusy {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.3)
                    .tint(.white)
            }
        }
        .suppressesAppOpenAd()
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("Paywall")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case let .message(title, text, finishes):
                CustomAlertView(
                    title: title.isEmpty ? nil : LocalizedStringKey(title),
                    description: LocalizedStringKey(text),
                    cancelActionTitle: nil,
                    primaryActionTitle: LocalizedStringKey("ok".localized),
                    primaryActionTitleColor: .white,
                    primaryAction: { viewModel.closeAlert(finishes: finishes) }
                )
            }
        } customize: { params in
            params.centerPopup().closeOnTap(false).closeOnTapOutside(false).backgroundColor(.dialogDim)
        }
    }
}

// MARK: - Sections

private extension PaywallView {
    /// The fade sits on the image so it reaches solid white at the artwork's bottom edge (no seam on tall screens).
    var hero: some View {
        Asset.Image.imgInappHero.image
            .resizable()
            .scaledToFit()
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0.23),
                        .init(color: .white.opacity(0.9), location: 0.43),
                        .init(color: .white.opacity(0.9), location: 0.8),
                        .init(color: .white, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    var content: some View {
        VStack(spacing: 0) {
            titleBlock
                .padding(.horizontal, Layout.Spacing.m)

            VStack(spacing: Layout.Spacing.s) {
                plans
                reassurance
            }
            .padding(.top, Layout.Spacing.l)
            .padding(.horizontal, Layout.Spacing.m)

            getStartedButton
                .padding(.top, Layout.Spacing.sm)
                .padding(.horizontal, Layout.Spacing.m)

            footer
                .padding(.top, Layout.Spacing.m)
                .padding(.horizontal, Layout.Spacing.m)

            Text(viewModel.policyText)
                .font(FontFamily.Poppins.regular.font(size: 10))
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
                .padding(.top, Layout.Spacing.s)
                .padding(.horizontal, 22)
                .padding(.bottom, Layout.Spacing.xs)
        }
    }

    var titleBlock: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.sm) {
            Text("inapp_premium_title".localized)
                .font(FontFamily.Poppins.bold.font(size: 40))
                .foregroundStyle(LinearGradient.primaryLinear)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: Layout.Spacing.s) {
                featureRow("inapp_feature_playlists")
                featureRow("inapp_feature_playback")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func featureRow(_ key: String) -> some View {
        HStack(spacing: Layout.Spacing.s) {
            Asset.Icon.icDiamond.image
                .resizable()
                .frame(width: 24, height: 24)

            Text(key.localized)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text1)
        }
    }

    var plans: some View {
        VStack(spacing: Layout.Spacing.s) {
            ForEach(viewModel.products, id: \.product.id) { product in
                PaywallProductRow(
                    title: viewModel.title(for: product),
                    detail: viewModel.detail(for: product),
                    price: product.displayPrice,
                    period: viewModel.period(for: product),
                    isSelected: product.id == viewModel.selectedID,
                    isMostPopular: product.key == .year,
                    onTap: { viewModel.select(product) }
                )
            }
        }
        .frame(minHeight: viewModel.products.isEmpty ? 235 : nil, alignment: .top)
    }

    var reassurance: some View {
        HStack(spacing: Layout.Spacing.s) {
            Asset.Icon.icShieldDone.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.primary1)
                .frame(width: 16, height: 16)

            Text(viewModel.reassuranceText)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.text2)
        }
    }

    var getStartedButton: some View {
        Button(action: viewModel.didTapContinue) {
            HStack(spacing: Layout.Spacing.s) {
                Asset.Icon.icCrown.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text("inapp_get_started".localized)
                    .font(Typography.subtitleSmall)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.primary1, in: RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }

    var footer: some View {
        HStack {
            footerButton("terms_of_use".localized, action: viewModel.didTapTerms)
            Spacer()
            footerButton("restore".localized, action: viewModel.didTapRestore)
            Spacer()
            footerButton("privacy_policy".localized, action: viewModel.didTapPrivacy)
        }
    }

    func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.captionMedium)
                .underline()
                .foregroundStyle(Color.primary1)
                .frame(minHeight: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Leaves the paywall without buying (the former "continue with limited version").
    var closeButton: some View {
        Button(action: viewModel.didTapLimitedVersion) {
            Asset.Icon.icClose.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 9, height: 9)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.2), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 6)
    }
}
