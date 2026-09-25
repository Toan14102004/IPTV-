//
//  NativeAdBannerView.swift
//  I340_IPTV
//

import SwiftUI
import UIKit

/// SwiftUI slot for a UIKit native ad view. Ad loading, refresh and 2F/MF priority are handled
/// by `NativeAdController`.
///
///     NativeAdBannerView(config: .init(adIdNormal: .ADSNativeLanguageAdsID), height: 262) {
///         LargeNativeAdViewOnboard(frame: .zero)
///     }
struct NativeAdBannerView: View {
    @StateObject private var controller: NativeAdController
    /// Fixed slot height, or nil to fill the available space (full-screen ads).
    private let height: CGFloat?

    init(
        config: NativeAdController.Config,
        height: CGFloat?,
        makeAdView: @escaping () -> NativeAdViewProtocol
    ) {
        _controller = StateObject(wrappedValue: NativeAdController(config: config, makeAdView: makeAdView))
        self.height = height
    }

    var body: some View {
        Group {
            if controller.isAvailable {
                // Kept in the hierarchy even when collapsed so a later refresh can show it again.
                NativeAdRepresentable(adView: controller.adView)
                    .frame(maxWidth: .infinity)
                    .frame(height: slotHeight)
                    .clipped()
            }
        }
        .onAppear(perform: controller.appear)
        .onDisappear(perform: controller.disappear)
    }

    private var slotHeight: CGFloat? {
        if controller.isCollapsed { return 0 }
        return height
    }
}

private struct NativeAdRepresentable: UIViewRepresentable {
    let adView: UIView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        adView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(adView)

        // Below required so the view's own "gone" size constraints never fight the layout.
        let edges = [
            adView.topAnchor.constraint(equalTo: container.topAnchor),
            adView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            adView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ]
        edges.forEach { $0.priority = UILayoutPriority(rawValue: 999) }
        NSLayoutConstraint.activate(edges)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
