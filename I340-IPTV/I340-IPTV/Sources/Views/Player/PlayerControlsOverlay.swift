//
//  PlayerControlsOverlay.swift
//  I340_IPTV
//

import AVKit
import SwiftUI

/// Everything drawn over the video: loading / offline overlay and the controls (back, lock,
/// play/pause, brightness and volume bars, progress, mute and fullscreen).
struct PlayerControlsOverlay: View {
    /// Extras of the Xtream player: ±15s buttons, cast, "more" menu and time labels.
    struct Extras {
        var onMore: () -> Void
    }

    @ObservedObject var controller: PlayerController
    let loadingText: String
    let networkLostText: String
    let onBack: () -> Void
    var extras: Extras?

    private let dim = Color.black.opacity(0.18)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if controller.isLocked || controller.isControlsVisible {
                    dim
                }

                if controller.isLocked {
                    lockedControls
                } else if controller.isControlsVisible {
                    controls(in: proxy.size)
                }

                if !controller.isFullscreen && !controller.isLocked {
                    backButton
                }

                statusOverlay
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: controller.didTapPlayerArea)
        }
    }
}

// MARK: - Status

private extension PlayerControlsOverlay {
    @ViewBuilder
    var statusOverlay: some View {
        switch controller.phase {
        case .loading:
            statusView(text: loadingText, showsSpinner: true)
        case .networkLost:
            statusView(text: networkLostText, showsSpinner: false)
        default:
            EmptyView()
        }
    }

    func statusView(text: String, showsSpinner: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.45)
            VStack(spacing: 10) {
                if showsSpinner {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.4)
                        .tint(.white)
                        .frame(height: 30)
                }
                Text(text)
                    .font(FontFamily.Poppins.medium.font(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, Layout.Spacing.l)
            }
            .offset(y: -12)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Buttons

private extension PlayerControlsOverlay {
    var backButton: some View {
        VStack {
            HStack {
                Button(action: onBack) {
                    Asset.Image.Movies.icBackXtream.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .padding(9)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.leading, 28)
            .padding(.top, 18)
            Spacer()
        }
    }

    var lockButton: some View {
        Button(action: controller.toggleLock) {
            Asset.Image.Movies.icLockXtream.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(Layout.Spacing.s)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.2))
                .clipShape(Circle())
                .frame(height: 38)
        }
        .buttonStyle(.plain)
    }

    /// Only the lock button stays while the controls are locked.
    var lockedControls: some View {
        VStack {
            HStack {
                lockButton
                    .padding(.leading, 74)
                Spacer()
            }
            .padding(.top, 18)
            Spacer()
        }
    }

    func controls(in size: CGSize) -> some View {
        ZStack {
            VStack {
                HStack {
                    lockButton
                        .padding(.leading, 74)
                    Spacer()
                    if let extras {
                        HStack(spacing: Layout.Spacing.s) {
                            CastButton()
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.2))
                                .clipShape(Circle())
                            roundButton(systemImage: "ellipsis", action: extras.onMore)
                        }
                        .padding(.trailing, Layout.Spacing.m)
                    }
                }
                .padding(.top, 18)
                Spacer()
            }

            if extras != nil {
                HStack(spacing: 85) {
                    skipButton(systemImage: "gobackward.15") { controller.seek(by: -15) }
                    Color.clear.frame(width: 58, height: 1)
                    skipButton(systemImage: "goforward.15") { controller.seek(by: 15) }
                }
            }

            playPauseButton

            // Brightness (left) and volume (right), centered between the top bar and the progress bar.
            let barsCenterY = (56 + (size.height - 60)) / 2
            adjustmentControl(
                systemImage: "sun.max.fill",
                value: Double(controller.brightness),
                onTapIcon: controller.toggleBrightnessPreset,
                onDragIcon: { controller.adjustBrightness(by: CGFloat($0)) },
                onSetValue: { controller.setBrightness(CGFloat($0)) }
            )
            .position(x: 34 + 11, y: barsCenterY)

            adjustmentControl(
                systemImage: volumeSymbol,
                value: controller.isMuted ? 0 : Double(controller.volume),
                onTapIcon: controller.toggleVolumePreset,
                onDragIcon: { controller.adjustVolume(by: Float($0)) },
                onSetValue: { controller.setVolume(Float($0)) }
            )
            .position(x: size.width - 34 - 11, y: barsCenterY)

            bottomControls
        }
    }

    func roundButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.2))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    func skipButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 26))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    var playPauseButton: some View {
        Button(action: controller.togglePlayback) {
            Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(Color.black.opacity(0.24))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    var volumeSymbol: String {
        if controller.isMuted || controller.volume == 0 { return "speaker.slash.fill" }
        return controller.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.2.fill"
    }
}

// MARK: - Bars

private extension PlayerControlsOverlay {
    /// Icon over a 68pt vertical bar; tap or drag the bar to set the value, drag the icon to nudge it.
    func adjustmentControl(
        systemImage: String,
        value: Double,
        onTapIcon: @escaping () -> Void,
        onDragIcon: @escaping (Double) -> Void,
        onSetValue: @escaping (Double) -> Void
    ) -> some View {
        VStack(spacing: Layout.Spacing.sm) {
            AdjustmentIcon(
                systemImage: systemImage,
                alpha: 0.45 + 0.55 * value,
                onTap: onTapIcon,
                onDrag: onDragIcon
            )

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: Layout.CornerRadius.small).fill(Color.white.opacity(0.28))
                RoundedRectangle(cornerRadius: Layout.CornerRadius.small)
                    .fill(Color.white)
                    .frame(height: 68 * CGFloat(max(0, min(value, 1))))
            }
            .frame(width: 8, height: 68)
            .contentShape(Rectangle().inset(by: -10))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        onSetValue(1 - Double(max(0, min(drag.location.y / 68, 1))))
                    }
            )
        }
        .frame(width: 22, height: 102, alignment: .top)
    }

    var bottomControls: some View {
        VStack {
            Spacer()
            VStack(spacing: Layout.Spacing.s) {
                ProgressTrack(progress: controller.progress) { controller.seek(toFraction: $0) }
                    .frame(height: 4)

                HStack(spacing: Layout.Spacing.sm) {
                    if extras != nil {
                        timeLabel(controller.elapsedText)
                    }

                    Button(action: controller.toggleMute) {
                        Image(systemName: volumeSymbol)
                            .foregroundColor(.white)
                            .opacity(0.45 + 0.55 * Double(controller.isMuted ? 0 : controller.volume))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: controller.toggleFullscreen) {
                        Group {
                            if controller.isFullscreen {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Asset.Image.Movies.icFullScreenXtream.image
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)

                    if extras != nil {
                        timeLabel(controller.remainingText)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, Layout.Spacing.xl)
        }
    }
}

private extension PlayerControlsOverlay {
    func timeLabel(_ text: String) -> some View {
        Text(text)
            .font(FontFamily.Poppins.regular.font(size: 12))
            .foregroundColor(.white)
            .monospacedDigit()
    }
}

/// AirPlay picker drawn as a plain white icon.
private struct CastButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.tintColor = .white
        view.activeTintColor = .white
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

private struct AdjustmentIcon: View {
    let systemImage: String
    let alpha: Double
    let onTap: () -> Void
    let onDrag: (Double) -> Void

    @State private var lastTranslation: CGFloat = 0

    var body: some View {
        Image(systemName: systemImage)
            .foregroundColor(.white)
            .opacity(alpha)
            .frame(width: 22, height: 22)
            .contentShape(Rectangle().inset(by: -8))
            .onTapGesture(perform: onTap)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { drag in
                        let delta = drag.translation.height - lastTranslation
                        lastTranslation = drag.translation.height
                        onDrag(Double(-delta / 180))
                    }
                    .onEnded { _ in lastTranslation = 0 }
            )
    }
}

private struct ProgressTrack: View {
    let progress: Double
    let onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.35))
                Capsule()
                    .fill(Color.white)
                    .frame(width: proxy.size.width * CGFloat(max(0, min(progress, 1))))
            }
            .contentShape(Rectangle().inset(by: -12))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { drag in onSeek(Double(drag.location.x / max(proxy.size.width, 1))) }
            )
        }
    }
}
