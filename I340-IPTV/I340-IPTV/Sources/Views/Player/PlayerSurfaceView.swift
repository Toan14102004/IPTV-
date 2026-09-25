//
//  PlayerSurfaceView.swift
//  I340_IPTV
//

import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

/// The video itself: an `AVPlayerLayer` laid out according to the chosen aspect ratio.
/// It also hosts the invisible `MPVolumeView` the controller uses to change the system volume.
struct PlayerSurfaceView: UIViewRepresentable {
    @ObservedObject var controller: PlayerController

    func makeUIView(context: Context) -> PlayerSurfaceContainer {
        let container = PlayerSurfaceContainer()
        controller.attach(volumeView: container.volumeView)
        return container
    }

    func updateUIView(_ container: PlayerSurfaceContainer, context: Context) {
        container.player = controller.player
        container.aspect = controller.aspect
    }
}

final class PlayerSurfaceContainer: UIView {
    let volumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    private let layerView = PlayerLayerView()

    var player: AVPlayer? {
        didSet { layerView.playerLayer.player = player }
    }

    var aspect: DetailXtreamAspectRatioOption = .default {
        didSet { setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        addSubview(layerView)

        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = true
        volumeView.alpha = 0.0001
        addSubview(volumeView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        switch aspect {
        case .default:
            layerView.frame = bounds
            layerView.playerLayer.videoGravity = .resizeAspect
        case .cropToFill:
            layerView.frame = bounds
            layerView.playerLayer.videoGravity = .resizeAspectFill
        case let .ratio(ratio):
            layerView.frame = Self.fittedFrame(for: ratio, in: bounds)
            layerView.playerLayer.videoGravity = .resizeAspectFill
        }
    }

    private static func fittedFrame(for ratio: CGFloat, in bounds: CGRect) -> CGRect {
        guard ratio > 0 else { return bounds }
        let containerRatio = bounds.width / bounds.height
        let size = ratio > containerRatio
            ? CGSize(width: bounds.width, height: bounds.width / ratio)
            : CGSize(width: bounds.height * ratio, height: bounds.height)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

private final class PlayerLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }
}
