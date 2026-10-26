//
//  WatchRoomView.swift
//  I340_IPTV
//

import SwiftUI

/// Viewer side of a room: plays the host's movie from the relay and follows the room's clock.
/// The viewer cannot control playback.
struct WatchRoomView: View {
    @StateObject private var viewModel: ViewModel

    init(code: String, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(code: code, onBack: onBack))
    }

    var body: some View {
        WatchRoomContent(viewModel: viewModel, player: viewModel.player)
    }
}

private struct WatchRoomContent: View {
    @ObservedObject var viewModel: WatchRoomView.ViewModel
    /// Observed directly: changes of this nested object do not notify `viewModel`.
    @ObservedObject var player: PlayerController

    var body: some View {
        content
            .overlay(alignment: .top) { bannerView }
            .animation(.easeOut(duration: 0.25), value: viewModel.banner)
            .ignoresSafeArea(edges: player.isFullscreen ? .all : [])
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .trackScreen("WatchRoom")
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
            .popup(isPresented: $viewModel.isEndedDialogPresented) {
                endedDialog
            } customize: { params in
                params.centerPopup().closeOnTap(false).closeOnTapOutside(false).backgroundColor(.dialogDim)
            }
    }

    private var content: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                if !player.isFullscreen {
                    ScreenHeader(
                        title: viewModel.title,
                        onBack: viewModel.didTapBack,
                        onLeave: { viewModel.didTapBack() }
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

    @ViewBuilder
    private var bannerView: some View {
        if let banner = viewModel.banner {
            RoomBannerView(banner: banner, onClose: viewModel.dismissBanner)
                .padding(.top, 36)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var playerArea: some View {
        ZStack {
            Color.black

            PlayerSurfaceView(controller: player)

            if viewModel.status == .watching {
                PlayVideoControlsOverlay(
                    controller: player,
                    title: viewModel.title,
                    loadingText: "playlist_player_loading".localized(fallback: "Loading channel..."),
                    onClose: viewModel.didTapBack,
                    onMore: {},
                    onCast: viewModel.showAudioOutput,
                    room: viewModel.roomPlayback,
                    isBusy: viewModel.isRoomPlaying && !player.isPlaying,
                    isReadOnly: true,
                    isLive: viewModel.snapshot?.isLive == true
                )
            } else {
                statusView
            }
        }
        .overlay(alignment: .bottom) { hostOfflineNotice }
        .frame(height: player.isFullscreen ? nil : UIScreen.main.bounds.width * 257 / 375)
        .frame(maxHeight: player.isFullscreen ? .infinity : nil)
        .clipped()
    }

    /// The host lost the network: the room is kept for a short while and shows how long.
    @ViewBuilder
    private var hostOfflineNotice: some View {
        if viewModel.snapshot?.hostConnected == false {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let seconds = viewModel.hostReconnectSecondsLeft(at: context.date) {
                    Text(String(
                        format: "watch_together_waiting_host".localized(fallback: "Waiting for the host to reconnect… %ds"),
                        seconds
                    ))
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Layout.Spacing.m)
                    .frame(height: 32)
                    .background(Color.black.opacity(0.6), in: Capsule())
                    .padding(.bottom, Layout.Spacing.m)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var statusView: some View {
        VStack(spacing: Layout.Spacing.s) {
            if viewModel.isBusy {
                ProgressView().tint(.white)
            }
            if let text = viewModel.statusText {
                Text(text)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            if let code = viewModel.errorCode {
                Text("(\(code))")
                    .font(Typography.labelSmall)
                    .foregroundStyle(.white.opacity(0.7))
            }
            if case .failed = viewModel.status {
                Button(action: viewModel.retry) {
                    Text("watch_together_retry".localized(fallback: "Try again"))
                        .underline()
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Layout.Spacing.l)
    }

    private var roomArea: some View {
        VStack(spacing: 0) {
            viewerRow
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.s)

            Spacer(minLength: Layout.Spacing.m)

            VStack(spacing: Layout.Spacing.l) {
                RoomWatchingView(
                    participants: viewModel.participants,
                    count: viewModel.watcherCount,
                    onViewList: viewModel.showPeople
                )
                RoomCodeBox(code: viewModel.code, isCopied: viewModel.isCodeCopied, onTap: viewModel.copyCode)
            }

            Spacer(minLength: Layout.Spacing.m)
        }
    }

    private var viewerRow: some View {
        HStack(spacing: Layout.Spacing.s) {
            RoomAvatarView(avatar: viewModel.identity.avatar, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.identity.name)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)
                Text("watch_together_viewer".localized(fallback: "Viewer"))
                    .font(FontFamily.Poppins.regular.font(size: 10))
                    .foregroundStyle(Color.text4)
                    .padding(.horizontal, Layout.Spacing.s)
                    .padding(.vertical, 1)
                    .background(Color.primary1, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: viewModel.showInvite) {
                HStack(spacing: Layout.Spacing.xs) {
                    Asset.Icon.icRoomInvite.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("watch_together_invite".localized(fallback: "Invite"))
                        .font(Typography.bodyMedium)
                }
                .foregroundStyle(Color.text2)
                .padding(.horizontal, Layout.Spacing.s)
                .frame(height: 38)
                .background(Color.neutral1, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: PlayVideoView.Sheet) -> some View {
        switch sheet {
        case .invite:
            InviteRoomSheet(
                code: viewModel.code,
                isCopied: viewModel.isCodeCopied,
                onCopy: viewModel.copyCode,
                onShare: viewModel.shareCode
            )
        case .audioOutput:
            AudioOutputSheet(onCancel: { viewModel.sheet = nil }, onConnect: viewModel.connectAudioOutput)
        case .people, .speed:
            PeopleInRoomSheet(participants: viewModel.participants, count: viewModel.watcherCount)
        }
    }

    private var leaveDialog: some View {
        AppDialogView(
            image: Asset.Image.imgLeaveRoom,
            imageHeight: 44,
            imageSpacing: Layout.Spacing.m,
            title: "watch_together_leave_title".localized(fallback: "Leave the room?"),
            message: "room_leave_message".localized(fallback: "You’ll stop watching with this room."),
            secondaryTitle: "cancel".localized(fallback: "Cancel"),
            primaryTitle: "watch_together_leave".localized(fallback: "Leave"),
            onSecondary: viewModel.cancelLeave,
            onPrimary: viewModel.confirmLeave,
            secondaryColor: Color.text2,
            primaryColor: Color.roomLeave
        )
    }

    private var endedDialog: some View {
        VStack(spacing: Layout.Spacing.xs) {
            Text("room_ended_title".localized(fallback: "Room Ended"))
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
            Text(viewModel.endedMessage)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)

            Button(action: viewModel.endedAcknowledged) {
                Text("ok".localized(fallback: "OK"))
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.primary1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, Layout.Spacing.s)
        }
        .padding(.top, 20)
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.bottom, Layout.Spacing.xs)
        .frame(maxWidth: .infinity)
        .background(Color.background1, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, Layout.Spacing.m)
    }
}
