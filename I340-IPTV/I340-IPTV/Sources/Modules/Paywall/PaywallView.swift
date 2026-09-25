//
//  PaywallView.swift
//  I340_IPTV
//

import SwiftUI

/// Premium paywall: plans, purchase, restore and the "limited version" exit.
struct PaywallView: View {
    @StateObject private var viewModel: ViewModel

    private let red = Asset.Color.brandRed.color

    init(onFinish: @escaping (_ isPurchased: Bool) -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onFinish: onFinish))
    }

    var body: some View {
        ZStack {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    titleBlock
                    plans
                    continueButton
                    limitedVersionButton
                    footer
                    Text(viewModel.policyText)
                        .font(FontFamily.Poppins.regular.font(size: 11))
                        .foregroundColor(Asset.Color.textTertiary.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Layout.Spacing.m)
                        .padding(.horizontal, Layout.Spacing.m)
                        .padding(.bottom, Layout.Spacing.l)
                        .onLongPressGesture(perform: viewModel.didLongPressTitle)
                }
            }
            .ignoresSafeArea(edges: .top)

            if viewModel.isBusy {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.3)
                    .tint(.white)
            }
        }
        .statusBar(hidden: true)
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
            case .voucher:
                VoucherPromptView(onCancel: viewModel.dismissAlert, onSubmit: viewModel.submitVoucher)
            }
        } customize: { params in
            params.centerPopup().closeOnTap(false).closeOnTapOutside(false).backgroundColor(.dialogDim)
        }
    }
}

// MARK: - Sections

private extension PaywallView {
    var hero: some View {
        Asset.Image.imgInappHero.image
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(393 / 272.3, contentMode: .fit)
            .background(Color.black)
            .clipped()
    }

    var titleBlock: some View {
        VStack(spacing: 6) {
            highlightedTitle
                .font(FontFamily.Poppins.semiBold.font(size: 26))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .onLongPressGesture(perform: viewModel.didLongPressTitle)

            Text("inapp_subtitle".localized)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .foregroundColor(Asset.Color.textSoft.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.s)
        }
        .padding(.top, Layout.Spacing.m)
        .padding(.horizontal, Layout.Spacing.m)
    }

    /// "Unlock IPTV Player Premium" with the highlighted part in red.
    var highlightedTitle: Text {
        let title = "inapp_title".localized
        let highlight = "inapp_title_highlight".localized
        guard let range = title.range(of: highlight) else {
            return Text(title).foregroundColor(.white)
        }
        return Text(String(title[..<range.lowerBound])).foregroundColor(.white)
            + Text(highlight).foregroundColor(red)
            + Text(String(title[range.upperBound...])).foregroundColor(.white)
    }

    var plans: some View {
        VStack(spacing: 14) {
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
        .padding(.top, Layout.Spacing.l)
        .padding(.horizontal, Layout.Spacing.m)
        .frame(minHeight: viewModel.products.isEmpty ? 270 : nil, alignment: .top)
    }

    var continueButton: some View {
        Button(action: viewModel.didTapContinue) {
            Text("continue".localized)
                .font(FontFamily.Poppins.semiBold.font(size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Asset.Color.brandRedDark.color, red, Asset.Color.brandRedDark.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
        }
        .buttonStyle(.plain)
        .padding(.top, Layout.Spacing.l)
        .padding(.horizontal, Layout.Spacing.m)
    }

    var limitedVersionButton: some View {
        Button(action: viewModel.didTapLimitedVersion) {
            Text("continue_with_limited_version".localized)
                .font(FontFamily.Poppins.regular.font(size: 12))
                .foregroundColor(red)
                .frame(height: 27)
                .padding(.horizontal, Layout.Spacing.sm)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }

    var footer: some View {
        HStack {
            footerButton("terms_of_use".localized, action: viewModel.didTapTerms)
            Spacer()
            footerButton("restore".localized, action: viewModel.didTapRestore)
            Spacer()
            footerButton("privacy_policy".localized, action: viewModel.didTapPrivacy)
        }
        .padding(.top, 14)
        .padding(.horizontal, Layout.Spacing.m)
    }

    func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FontFamily.Poppins.medium.font(size: 12))
                .underline()
                .foregroundColor(Asset.Color.textTertiary.color)
                .frame(height: 24)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Voucher prompt

/// Hidden "enter premium code" prompt.
private struct VoucherPromptView: View {
    let onCancel: () -> Void
    let onSubmit: (String) -> Void

    @State private var code = ""

    var body: some View {
        VStack(spacing: Layout.Spacing.m) {
            Text("iap_enter_premium_code".localized)
                .font(FontFamily.Poppins.semiBold.font(size: 16))
                .foregroundColor(.white)

            TextField("", text: $code)
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .padding(.horizontal, Layout.Spacing.sm)
                .frame(height: 44)
                .background(Asset.Color.fieldBackground.color)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: Layout.Spacing.sm) {
                button("cancel".localized, color: Asset.Color.buttonNeutral.color, action: onCancel)
                button("submit".localized, color: Asset.Color.brandRedButton.color) { onSubmit(code) }
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(Asset.Color.dialogBackground.color)
        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.xl))
    }

    private func button(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FontFamily.Poppins.medium.font(size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
}
