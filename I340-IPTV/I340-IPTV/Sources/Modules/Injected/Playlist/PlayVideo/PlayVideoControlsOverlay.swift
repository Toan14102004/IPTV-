//
//  PlayVideoControlsOverlay.swift
//  I340_IPTV
//

import AVKit
import SwiftUI

/// Controls of the Play Video player (Figma "Play Video"): close, cast and more on top, ±15s and
/// play/pause in the middle, title, time, progress, volume and fullscreen at the bottom.
struct PlayVideoControlsOverlay: View {
    /// While a room is live the movie clock is the server's, not the player's: position, length
    /// and every jump go through the room.
    struct RoomPlayback {
        let position: () -> Double
        let duration: Double
        let onSkip: (Double) -> Void
        let onSeek: (Double) -> Void
    }

    @ObservedObject var controller: PlayerController
    let title: String
    let loadingText: String
    let onClose: () -> Void
    let onMore: () -> Void
    /// Opens the Audio Output sheet; without it the system AirPlay picker opens directly.
    var onCast: (() -> Void)?
    var room: RoomPlayback?
    /// The room's source is being prepared; the screen is waiting rather than failing.
    var isBusy = false
    /// A viewer only watches: play, pause, jumps and the progress bar belong to the host.
    var isReadOnly = false
    /// A live channel has no length: LIVE replaces the progress bar and the time.
    var isLive = false

    @State private var dragFraction: Double?

    var body: some View {
        ZStack {
            if controller.isControlsVisible {
                LinearGradient(
                    colors: [.black.opacity(0.35), .clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 0)
                    bottomBar
                }

                // Hidden while busy or stalled: waiting for data reads as "paused" to the player,
                // and a play button over the spinner makes a buffer gap look like a failure.
                if !isReadOnly, !isBusy, !controller.isStalled {
                    centerControls
                }
            }

            if isLive {
                liveBadge
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }

            if controller.phase == .loading || isBusy || controller.isStalled {
                VStack(spacing: Layout.Spacing.s) {
                    ProgressView().tint(.white)
                    Text(loadingText)
                        .font(Typography.labelMedium)
                        .foregroundStyle(.white)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: controller.didTapPlayerArea)
    }
}

// MARK: - Sections

private extension PlayVideoControlsOverlay {
    var topBar: some View {
        HStack(spacing: 0) {
            Button(action: onClose) {
                icon(Asset.Icon.icPlayerClose, size: 24)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                if let onCast {
                    Button(action: onCast) {
                        smallCircle { icon(Asset.Icon.icPlayerCast, size: 14) }
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    ZStack {
                        smallCircle { icon(Asset.Icon.icPlayerCast, size: 14) }
                        RoutePicker().frame(width: 24, height: 24)
                    }
                }
                if !isReadOnly {
                    Button(action: onMore) {
                        smallCircle { icon(Asset.Icon.icPlayerMore, size: 14) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.top, 10)
    }

    var liveBadge: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.white).frame(width: 6, height: 6)
            Text("player_live".localized(fallback: "LIVE"))
                .font(FontFamily.Poppins.semiBold.font(size: 10))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Layout.Spacing.s)
        .frame(height: 20)
        .background(Color.roomLeave, in: Capsule())
    }

    var centerControls: some View {
        HStack(spacing: 12) {
            // A live channel has no fixed timeline to skip within; seeking on one just forces a reload.
            if !isLive {
                Button { skip(-15) } label: {
                    icon(Asset.Icon.icPlayerRewind15, size: 19)
                        .frame(width: 37.5, height: 37.5)
                        .background(Color.black.opacity(0.25), in: Circle())
                }
            }
            Button(action: controller.togglePlayback) {
                Group {
                    if controller.isPlaying {
                        icon(Asset.Icon.icPlayerSmallToggle, size: 26)
                    } else {
                        icon(Asset.Icon.icPlayerPlay, size: 34)
                    }
                }
                .frame(width: 56, height: 56)
                .background(Color.black.opacity(0.25), in: Circle())
            }
            if !isLive {
                Button { skip(15) } label: {
                    icon(Asset.Icon.icPlayerForward15, size: 19)
                        .frame(width: 37.5, height: 37.5)
                        .background(Color.black.opacity(0.25), in: Circle())
                }
            }
        }
        .buttonStyle(.plain)
    }

    var bottomBar: some View {
        VStack(spacing: Layout.Spacing.sm) {
            HStack(spacing: Layout.Spacing.s) {
                Text(title)
                    .font(Typography.bodyLarge)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.white)

            if !isLive {
                progressBar
                    .allowsHitTesting(!isReadOnly)
            }

            HStack(spacing: Layout.Spacing.xs) {
                if !isReadOnly {
                    Button(action: controller.togglePlayback) {
                        smallCircle {
                            icon(
                                controller.isPlaying || controller.isStalled
                                    ? Asset.Icon.icPlayerSmallToggle
                                    : Asset.Icon.icPlayerPlay,
                                size: 14
                            )
                        }
                    }
                }
                if !isLive {
                    Text(timeText)
                        .font(FontFamily.Poppins.regular.font(size: 10))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)

                Button(action: controller.toggleMute) {
                    smallCircle { icon(Asset.Icon.icPlayerVolume, size: 14) }
                        .opacity(controller.isMuted ? 0.5 : 1)
                }
                .padding(.trailing, Layout.Spacing.sm)
                Button(action: controller.toggleFullscreen) {
                    smallCircle { icon(Asset.Icon.icPlayerFullscreen, size: 14) }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.bottom, Layout.Spacing.s)
    }

    var progressBar: some View {
        GeometryReader { proxy in
            let fraction = dragFraction ?? progress
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.35))
                Capsule().fill(Color.surface1)
                    .frame(width: proxy.size.width * max(0, min(fraction, 1)))
            }
            .frame(height: 2)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragFraction = max(0, min(value.location.x / proxy.size.width, 1))
                        controller.showControls(autoHide: false)
                    }
                    .onEnded { _ in
                        if let dragFraction { seek(toFraction: dragFraction) }
                        dragFraction = nil
                    }
            )
        }
        .frame(height: 16)
    }

    /// "21:48 / 56:32".
    var timeText: String {
        let duration = room?.duration ?? controller.player?.currentItem?.duration.seconds ?? 0
        guard duration.isFinite, duration > 0 else { return controller.elapsedText }
        return "\(Self.clock((dragFraction ?? progress) * duration)) / \(Self.clock(duration))"
    }

    var progress: Double {
        guard let room else { return controller.progress }
        return room.duration > 0 ? max(0, min(room.position() / room.duration, 1)) : 0
    }

    func skip(_ seconds: Double) {
        if let room { room.onSkip(seconds) } else { controller.seek(by: seconds) }
    }

    func seek(toFraction fraction: Double) {
        if let room { room.onSeek(fraction) } else { controller.seek(toFraction: fraction) }
    }

    static func clock(_ seconds: Double) -> String {
        let total = Int(max(seconds, 0))
        let hours = total / 3600
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, (total % 3600) / 60, total % 60)
            : String(format: "%02d:%02d", total / 60, total % 60)
    }

    func icon(_ asset: ImageAsset, size: CGFloat) -> some View {
        asset.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: size, height: size)
    }

    func smallCircle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: 24, height: 24)
            .background(Color.black.opacity(0.25), in: Circle())
    }
}

/// AirPlay picker with its own glyph hidden, so the Figma cast icon underneath shows.
private struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.tintColor = .clear
        view.activeTintColor = .clear
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
