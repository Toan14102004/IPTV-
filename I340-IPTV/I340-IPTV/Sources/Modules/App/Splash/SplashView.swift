//
//  SplashView.swift
//  I340_IPTV
//

import AdsDebugKit
import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel: ViewModel

    init(isFromLanguageSetting: Bool) {
        _viewModel = StateObject(wrappedValue: ViewModel(isFromLanguageSetting: isFromLanguageSetting))
    }

    var body: some View {
        BaseView(background: Color.clear) {
            ZStack {
                Asset.Image.bgSplash.image
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                brand
                    .padding(.horizontal, Layout.Spacing.m)
                    .offset(y: -52)

                if !viewModel.isAdHintHidden {
                    loadingFooter
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}

// MARK: - Subviews

private extension SplashView {
    var brand: some View {
        VStack(spacing: 0) {
            Asset.Icon.icAppIcon.image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Asset.Color.iconBackground.color)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))
                .overlay(DebugGestureAnchor())

            Text("welcome_to".localized)
                .font(FontFamily.Poppins.medium.font(size: 18))
                .padding(.top, Layout.Spacing.sm)

            Text("IPTV Player")
                .font(FontFamily.Poppins.semiBold.font(size: 30))
                .foregroundStyle(Asset.Color.colorPrimaryLegacy.color)
                .padding(.top, Layout.Spacing.xxs)

            Text("splash_description".localized)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    var loadingFooter: some View {
        VStack(spacing: Layout.Spacing.s) {
            Spacer()

            ProgressBar(progress: viewModel.progress)
                .frame(height: 5)

            Text("this_action_can_contain_ads".localized)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Layout.Spacing.l)
        .padding(.bottom, 42)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Progress bar

/// Rounded bar like `UIProgressView`, tinted with the legacy primary color.
private struct ProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.22))
                Capsule()
                    .fill(Asset.Color.colorPrimaryLegacy.color)
                    .frame(width: proxy.size.width * CGFloat(progress))
            }
        }
        .animation(.linear(duration: 1), value: progress)
    }
}

// MARK: - Debug gesture

/// Transparent view carrying the Ads debug combo gesture (swipe down, double tap, swipe up)
/// that the UIKit splash attached to the app icon.
private struct DebugGestureAnchor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DebugComboGestureHelper().setup(on: view) {}
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    SplashView(isFromLanguageSetting: false)
        .preview()
}
