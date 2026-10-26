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
        BaseView(background: Color.white) {
            ZStack {
                brand
                    .padding(.horizontal, Layout.Spacing.m)
                    .offset(y: -62)

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
        VStack(spacing: Layout.Spacing.m) {
            Asset.Icon.icAppIcon.image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.xxl))
                .overlay(DebugGestureAnchor())

            VStack(spacing: Layout.Spacing.xs) {
                Text("splash_brand_title".localized)
                    .font(FontFamily.Poppins.bold.font(size: 34))
                    .foregroundStyle(LinearGradient.primaryLinear)

                Text("splash_brand_subtitle".localized)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.text1)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// Pinned 36pt above the screen edge like the design, whatever the bottom safe area.
    var loadingFooter: some View {
        VStack(spacing: Layout.Spacing.sm) {
            Spacer()

            ProgressBar(progress: viewModel.progress)
                .frame(maxWidth: 300)
                .frame(height: 8)

            Text("this_action_can_contain_ads".localized)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Progress bar

private struct ProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.surface2)
                Capsule()
                    .fill(LinearGradient.primaryLinear)
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
