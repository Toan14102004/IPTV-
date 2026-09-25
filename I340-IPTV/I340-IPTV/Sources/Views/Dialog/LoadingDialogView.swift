//
//  LoadingDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// Blocking "importing…" dialog with a spinner and a Close button.
struct LoadingDialogView: View {
    let title: String
    let message: String
    let closeTitle: String
    let onClose: () -> Void
    /// The Playlist and Xtream imports use slightly different surfaces.
    var background = Asset.Color.loadingDialogBackground.color
    var dimOpacity = 0.58

    var body: some View {
        ZStack {
            Color.black.opacity(dimOpacity)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SegmentSpinner()
                    .frame(width: 76, height: 76)
                    .padding(.top, 28)

                Text(title)
                    .font(FontFamily.Poppins.semiBold.font(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                Text(message)
                    .font(FontFamily.Poppins.regular.font(size: 12))
                    .foregroundColor(Asset.Color.textSubtitle.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 10)

                Spacer(minLength: 0)

                Button(action: onClose) {
                    Text(closeTitle)
                        .font(FontFamily.Poppins.medium.font(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.gradient(colors: [Asset.Color.brandRedDeep.color, Asset.Color.brandRed.color, Asset.Color.brandRedDeep.color], cornerRadius: 25))
                .padding(.bottom, Layout.Spacing.l)
            }
            .padding(.horizontal, 20)
            .frame(width: 283, height: 277)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.xxl))
            .offset(y: -18)
        }
    }
}

/// 12 radial bars fading around a circle, rotating once per second.
private struct SegmentSpinner: View {
    @State private var angle: Double = 0

    private let segmentCount = 12

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2 - 10
            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: Layout.CornerRadius.small)
                        .fill(Color.brand.opacity(0.25 + Double(index) / Double(segmentCount) * 0.75))
                        .frame(width: 8, height: 20)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(Double(index) * 360 / Double(segmentCount)))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .rotationEffect(.degrees(angle))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}
