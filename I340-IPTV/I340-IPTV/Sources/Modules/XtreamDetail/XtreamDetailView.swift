//
//  XtreamDetailView.swift
//  I340_IPTV
//

import SwiftUI

/// Player of an Xtream movie / series / live channel with the related channels underneath.
struct XtreamDetailView: View {
    @StateObject private var viewModel: ViewModel

    init(channel: IPTVChannel, related: [IPTVChannel], playlistID: String?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: ViewModel(channel: channel, relatedChannels: related, playlistID: playlistID, onBack: onBack)
        )
    }

    var body: some View {
        XtreamDetailContent(viewModel: viewModel, player: viewModel.player)
    }
}

private struct XtreamDetailContent: View {
    typealias ViewModel = XtreamDetailView.ViewModel
    typealias Coordinator = XtreamDetailView.Coordinator

    @ObservedObject var viewModel: ViewModel
    /// Observed directly: changes of this nested object do not notify `viewModel`.
    @ObservedObject var player: PlayerController

    var body: some View {
        ZStack(alignment: .top) {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            VStack(spacing: 0) {
                playerArea

                if !player.isFullscreen {
                    infoBar
                        .padding(.horizontal, Layout.Spacing.m)

                    relatedList
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !viewModel.isSubscribed {
                        NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                            MediumNativeAdView(frame: .zero)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: player.isFullscreen ? .all : [])
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .trackScreen("XtreamDetail")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            sheet(for: item)
        } customize: { params in
            params.bottomPopup().backgroundColor(Color.black.opacity(0.15))
        }
    }
}

// MARK: - Player

private extension XtreamDetailContent {
    var playerArea: some View {
        ZStack {
            Color.black

            PlayerSurfaceView(controller: player)

            PlayerControlsOverlay(
                controller: player,
                loadingText: viewModel.loadingText,
                networkLostText: viewModel.networkLostText,
                onBack: viewModel.didTapBack,
                extras: .init(onMore: viewModel.showMore)
            )

            if player.phase == .failed {
                errorView
            }
        }
        .frame(height: player.isFullscreen ? nil : UIScreen.main.bounds.height * 0.36)
        .frame(maxHeight: player.isFullscreen ? .infinity : nil)
        .clipped()
    }

    var errorView: some View {
        ZStack {
            Color(red: 0.52, green: 0.52, blue: 0.51)

            VStack(spacing: 0) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .padding(.bottom, 10)

                Text("xtream_video_cant_play_title".localized)
                    .font(FontFamily.Poppins.semiBold.font(size: 14))
                    .foregroundColor(.white)
                    .padding(.bottom, Layout.Spacing.xs)

                Text("xtream_video_cant_play_subtitle".localized)
                    .font(FontFamily.Poppins.regular.font(size: 12))
                    .foregroundColor(Color.white.opacity(0.28))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Layout.Spacing.m)

                Button(action: viewModel.retry) {
                    Text("xtream_try_again_now".localized)
                        .font(FontFamily.Poppins.semiBold.font(size: 14))
                        .foregroundColor(.white)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Layout.Spacing.l)

            VStack {
                HStack {
                    Button(action: viewModel.didTapBack) {
                        Asset.Icon.icArrowLeft.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .padding(Layout.Spacing.sm)
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.32))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.leading, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.sm)
                Spacer()
            }
        }
    }
}

// MARK: - Info & related

private extension XtreamDetailContent {
    var infoBar: some View {
        HStack(spacing: 18) {
            RemoteImageView(
                urlString: viewModel.currentChannel.imageURL,
                placeholder: Asset.Icon.icXtreamMovies,
                contentMode: .fill
            )
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.currentChannel.title)
                    .font(FontFamily.Poppins.medium.font(size: 24))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(viewModel.categoryText)
                    .font(FontFamily.Poppins.regular.font(size: 16))
                    .foregroundColor(Asset.Color.textGray.color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "waveform")
                .font(.system(size: 22))
                .foregroundColor(Asset.Color.brandRed.color)
        }
        .frame(height: 84)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Asset.Color.dividerBlue.color).frame(height: 1)
        }
    }

    var relatedList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.Spacing.m) {
                ForEach(viewModel.related) { channel in
                    XtreamRelatedRow(
                        channel: channel,
                        isFavorite: viewModel.isFavorite(channel),
                        onTap: { viewModel.play(channel) },
                        onFavorite: { viewModel.toggleFavorite(channel) }
                    )
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.vertical, Layout.Spacing.m)
        }
    }
}

// MARK: - Option sheets

private extension XtreamDetailContent {
    @ViewBuilder
    func sheet(for alert: Coordinator.Alert) -> some View {
        switch alert {
        case .more:
            PlayerOptionSheet(
                rows: [
                    .init(id: "speed", title: "xtream_playback_speed".localized,
                          icon: AnyView(Image(systemName: "speedometer").foregroundColor(.white)),
                          action: { viewModel.openOption(.playbackSpeed) }),
                    .init(id: "quality", title: "xtream_quality".localized,
                          icon: AnyView(
                              Text("HQ")
                                  .font(FontFamily.Poppins.medium.font(size: 9))
                                  .foregroundColor(.white)
                                  .frame(width: 22, height: 16)
                                  .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1.5))
                          ),
                          action: { viewModel.openOption(.quality) }),
                    .init(id: "aspect", title: "xtream_aspect_ratio".localized,
                          icon: AnyView(Image(systemName: "aspectratio").foregroundColor(.white)),
                          action: { viewModel.openOption(.aspectRatio) })
                ],
                showsChecks: false
            )
        case .playbackSpeed:
            PlayerOptionSheet(rows: viewModel.speedOptions.map { option in
                .init(id: option.title, title: option.title,
                      isSelected: abs(player.playbackRate - option.rate) < 0.001,
                      action: { viewModel.selectSpeed(option.rate) })
            })
        case .quality:
            PlayerOptionSheet(rows: viewModel.qualityOptions.map { option in
                .init(id: option.title, title: option.title,
                      isSelected: abs(player.qualityBitRate - option.bitRate) < 0.1,
                      action: { viewModel.selectQuality(option.bitRate) })
            })
        case .aspectRatio:
            PlayerOptionSheet(rows: viewModel.aspectOptions.map { option in
                .init(id: option.title, title: option.title,
                      isSelected: player.aspect == option,
                      action: { viewModel.selectAspect(option) })
            })
        }
    }
}
