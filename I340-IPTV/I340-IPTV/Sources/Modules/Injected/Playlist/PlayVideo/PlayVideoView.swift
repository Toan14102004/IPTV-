//
//  PlayVideoView.swift
//  I340_IPTV
//

import SwiftUI

/// Plays the first title of a playlist file (VIDEOS), with the watch-together room under it.
struct PlayVideoView: View {
    @StateObject private var viewModel: ViewModel

    init(playlist: IPTVPlaylist, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(playlist: playlist, onBack: onBack))
    }

    var body: some View {
        PlayVideoContent(viewModel: viewModel, player: viewModel.player)
    }
}

private struct PlayVideoContent: View {
    typealias ViewModel = PlayVideoView.ViewModel

    @ObservedObject var viewModel: ViewModel
    /// Observed directly: changes of this nested object do not notify `viewModel`.
    @ObservedObject var player: PlayerController

    var body: some View {
        content
            .overlay(alignment: .top) { bannerView }
            .animation(.easeOut(duration: 0.25), value: viewModel.banner)
            .ignoresSafeArea(edges: player.isFullscreen ? .all : [])
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .trackScreen("PlayVideo")
            .toast(message: $viewModel.toast)
            .popup(item: $viewModel.sheet) { sheet in
                sheetContent(for: sheet)
            } customize: { params in
                params.bottomPopup()
                    .closeOnTap(false)
                    .closeOnTapOutside(true)
                    .dragToDismiss(true)
                    .backgroundColor(Color.black.opacity(0.2))
            }
            .popup(isPresented: $viewModel.isLeaveDialogPresented) {
                leaveDialog
            } customize: { params in
                params.centerPopup().closeOnTapOutside(true).backgroundColor(.dialogDim)
            }
            .popup(isPresented: $viewModel.isPlaybackFailedPresented) {
                playbackFailedDialog
            } customize: { params in
                params.centerPopup().backgroundColor(.dialogDim)
            }
    }

    var content: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                if !player.isFullscreen {
                    ScreenHeader(
                        title: viewModel.title,
                        onBack: viewModel.didTapBack,
                        onPremium: premiumAction,
                        onLeave: leaveAction
                    )
                }

                playerArea

                if !player.isFullscreen {
                    roomArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    NativeAdBannerView(
                        config: .init(adIdNormal: .ADSNativeAdsNoMediaViewID),
                        height: ExtraSmallNativeAdView.height
                    ) {
                        ExtraSmallNativeAdView(frame: .zero)
                    }
                }
            }
        }
    }

    var premiumAction: (() -> Void)? {
        viewModel.isHosting ? nil : viewModel.premiumAction
    }

    var leaveAction: (() -> Void)? {
        viewModel.isHosting ? { viewModel.askLeave() } : nil
    }

    @ViewBuilder
    var bannerView: some View {
        if let banner = viewModel.banner {
            RoomBannerView(banner: banner, onClose: viewModel.dismissBanner)
                .padding(.top, 36)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    func sheetContent(for sheet: PlayVideoView.Sheet) -> some View {
        switch sheet {
        case .speed:
            PlayerOptionSheet(rows: speedRows)
        case .audioOutput:
            AudioOutputSheet(onCancel: { viewModel.sheet = nil }, onConnect: viewModel.connectAudioOutput)
        case .invite:
            InviteRoomSheet(
                code: viewModel.roomCode,
                isCopied: viewModel.isCodeCopied,
                onCopy: viewModel.copyCode,
                onShare: viewModel.shareCode
            )
        case .people:
            PeopleInRoomSheet(participants: viewModel.participants, count: viewModel.watcherCount)
        }
    }

    var speedRows: [PlayerOptionSheet.Row] {
        viewModel.speedOptions.map { option in
            PlayerOptionSheet.Row(
                id: option.title,
                title: option.title,
                isSelected: abs(player.playbackRate - option.rate) < 0.001,
                action: { viewModel.selectSpeed(option.rate) }
            )
        }
    }

    var leaveDialog: some View {
        AppDialogView(
            image: Asset.Image.imgLeaveRoom,
            imageHeight: 44,
            imageSpacing: Layout.Spacing.m,
            title: "watch_together_leave_title".localized(fallback: "Leave the room?"),
            message: "watch_together_leave_message".localized(
                fallback: "You will stop watching together with everyone here."
            ),
            secondaryTitle: "cancel".localized(fallback: "Cancel"),
            primaryTitle: "watch_together_leave".localized(fallback: "Leave"),
            onSecondary: viewModel.cancelLeave,
            onPrimary: viewModel.confirmLeave,
            secondaryColor: Color.text2,
            primaryColor: Color.roomLeave
        )
    }

    var playbackFailedDialog: some View {
        let hasNext = viewModel.hasNextChannel
        let primaryTitle = hasNext
            ? "playlist_player_next_channel".localized(fallback: "Next Channel")
            : "ok".localized(fallback: "OK")
        let onPrimary = hasNext ? viewModel.selectNextChannel : viewModel.dismissPlaybackFailedDialog

        return AppDialogView(
            image: Asset.Image.imgChannelUnavailable,
            imageHeight: 135,
            title: "playlist_player_error_title".localized(fallback: "Channel Unavailable"),
            message: "playlist_player_unavailable_message".localized(
                fallback: "This channel is currently unavailable. Please try again later."
            ),
            secondaryTitle: "cancel".localized(fallback: "Cancel"),
            primaryTitle: primaryTitle,
            onSecondary: viewModel.dismissPlaybackFailedDialog,
            onPrimary: onPrimary,
            secondaryColor: Color.text2,
            primaryColor: Color.primary1
        )
    }

    var playerArea: some View {
        ZStack {
            Color.black

            PlayerSurfaceView(controller: player)

            PlayVideoControlsOverlay(
                controller: player,
                title: viewModel.videoTitle,
                loadingText: viewModel.loadingText,
                onClose: viewModel.didTapBack,
                onMore: viewModel.showSpeedOptions,
                onCast: viewModel.showAudioOutput,
                room: viewModel.roomPlayback,
                isBusy: viewModel.relayState == .preparing || viewModel.isReconnecting,
                isLive: player.isLive
            )
        }
        .frame(height: player.isFullscreen ? nil : UIScreen.main.bounds.width * 257 / 375)
        .frame(maxHeight: player.isFullscreen ? .infinity : nil)
        .clipped()
    }

    @ViewBuilder
    var roomArea: some View {
        switch viewModel.roomState {
        case .idle, .creating:
            ScrollView(showsIndicators: false) {
                WatchTogetherCard(isCreating: viewModel.roomState == .creating, onCreate: viewModel.createRoom)
                    .padding(.horizontal, Layout.Spacing.l + Layout.Spacing.s)
                    .padding(.vertical, Layout.Spacing.l)
            }
        case .hosting:
            RoomPanel(viewModel: viewModel)
        }
    }
}

extension Color {
    /// Red of the leave button and icon in the room designs.
    static let roomLeave = Color(hex: 0xE73025)
}

// MARK: - Before the room exists

/// Light blue card: avatars, title and "Create Room".
private struct WatchTogetherCard: View {
    let isCreating: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Layout.Spacing.s) {
            Asset.Image.imgWatchTogetherAvatars.image
                .resizable()
                .scaledToFit()
                .frame(height: 49)

            VStack(spacing: Layout.Spacing.xs) {
                Text("watch_together_title".localized(fallback: "Watch Together"))
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text1)
                Text("watch_together_message".localized(fallback: "Create a room and watch with friends in real time"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Layout.Spacing.m)

            Button(action: onCreate) {
                HStack(spacing: Layout.Spacing.s) {
                    if isCreating {
                        ProgressView().tint(Color.text4)
                    } else {
                        Asset.Icon.icPlus.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    Text("watch_together_create".localized(fallback: "Create Room"))
                        .font(FontFamily.Poppins.bold.font(size: 14))
                }
                .foregroundStyle(Color.text4)
                .padding(.horizontal, Layout.Spacing.m)
                .frame(height: 36)
                .background(Color.primary1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isCreating)
            .padding(.top, Layout.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.Spacing.m)
        .background(
            LinearGradient(colors: [Color(hex: 0x8AD2FE), Color(hex: 0xE8F5FF)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}
