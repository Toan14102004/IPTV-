//
//  GetStartedView.swift
//  I340_IPTV
//

import SwiftUI

/// Welcome screen shown once, right after the splash on the first launch.
struct GetStartedView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Asset.Image.imgGetStartedBg.image
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                overlay
                    .frame(width: proxy.size.width, height: proxy.size.height)

                Asset.Image.imgGetStartedPhone.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding(.leading, Layout.Spacing.l)
                    .padding(.top, 26)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            // GeometryReader gives every view an explicit, concrete size instead of relying on
            // `.infinity`/proposed sizing: on iPad's regular size class, a `Spacer` pushing fixed
            // content toward an edge inside an `.infinity`-sized stack collapsed that content to
            // zero height instead of only taking the leftover space.
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    texts
                    buttonGetStarted
                }
            }
        }
        .ignoresSafeArea()
        // The app is locked to Light (Info.plist); dark here gives the white status bar of the design.
        .preferredColorScheme(.dark)
    }

    private var overlay: some View {
        let ink = Color(hex: 0x010423)
        return LinearGradient(
            stops: [
                .init(color: ink.opacity(0), location: 0.22),
                .init(color: ink.opacity(0.76), location: 0.59),
                .init(color: ink.opacity(0.6), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.sm) {
            Text(viewModel.title)
                .font(FontFamily.Poppins.bold.font(size: 34))
                .foregroundStyle(Color.text4)
                .minimumScaleFactor(0.7)

            Text(viewModel.message)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.text4.opacity(0.8))
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.vertical, 10)
    }

    private var buttonGetStarted: some View {
        Button(action: viewModel.didTapGetStarted) {
            HStack(spacing: Layout.Spacing.s) {
                Text(viewModel.buttonTitle)
                    .font(Typography.subtitleSmall)
                Asset.Icon.icArrowRight.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .foregroundStyle(Color.text4)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.top, Layout.Spacing.m)
        .padding(.bottom, Layout.Spacing.xl)
    }
}

#Preview {
    GetStartedView()
        .preview()
}
