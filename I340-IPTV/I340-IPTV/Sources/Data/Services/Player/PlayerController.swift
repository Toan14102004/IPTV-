//
//  PlayerController.swift
//  I340_IPTV
//

import AVFoundation
import Combine
import MediaPlayer
import RxSwift
import SwiftUI

/// Owns one `AVPlayer` and everything the player screens show around it: loading / offline /
/// error overlays, the auto-hiding controls, lock, volume, brightness and fullscreen.
///
/// The screens (`PlayerSurfaceView` + `PlayerControlsOverlay`) only render this state.
final class PlayerController: NSObject, ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case ready
        case failed
        case networkLost
    }

    // MARK: - State

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    /// "m:ss" of the position and of the time left; "--:--" for live streams.
    @Published private(set) var elapsedText = "--:--"
    @Published private(set) var remainingText = "--:--"
    @Published private(set) var isMuted = false
    @Published private(set) var volume: Float = 1
    @Published private(set) var brightness: CGFloat = UIScreen.main.brightness
    @Published private(set) var playbackRate: Float = 1
    @Published private(set) var qualityBitRate: Double = 0
    @Published private(set) var aspect: DetailXtreamAspectRatioOption = .default
    @Published private(set) var player: AVPlayer?
    /// The channel artwork stays on top of the video until playback really starts.
    @Published private(set) var showsPreview = true
    @Published private(set) var isControlsVisible = false
    @Published private(set) var isLocked = false
    @Published private(set) var isFullscreen = false

    // MARK: - Callbacks

    /// Playback started / stopped (drives the free watch-time limit).
    var onPlaybackStarted: (() -> Void)?
    var onPlaybackStopped: (() -> Void)?
    /// The stream with this id could not be played (bad URL, error or timeout).
    var onLoadFailed: ((String) -> Void)?

    /// Only react to connectivity changes while the screen is on screen.
    var isActive = false

    // MARK: - Private

    private let loadTimeout: TimeInterval = 30
    private let controlsAutoHideDelay: TimeInterval = 5

    private var currentRequest: (url: URL?, id: String)?
    private var loadingID: String?
    private var shouldReconnectWhenNetworkRestores = false
    private var statusObservation: NSKeyValueObservation?
    private var keepUpObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var outputVolumeObservation: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    private var loadingTimeoutWorkItem: DispatchWorkItem?
    private var controlsHideWorkItem: DispatchWorkItem?
    private weak var systemVolumeSlider: UISlider?
    private var lastVolume: Float = 1
    private let bag = DisposeBag()

    override init() {
        super.init()
        observeSystemVolume()
        observeNetwork()
    }

    deinit {
        outputVolumeObservation?.invalidate()
        loadingTimeoutWorkItem?.cancel()
        controlsHideWorkItem?.cancel()
        tearDownPlayer()
    }

    // MARK: - Loading

    /// Starts playing `url`; `id` identifies the request so stale callbacks are ignored.
    func load(url: URL?, id: String) {
        cleanup()
        currentRequest = (url, id)
        showsPreview = true

        guard let url else {
            failLoad(id: id)
            return
        }
        guard NetworkOverlayManager.shared.isConnected else {
            shouldReconnectWhenNetworkRestores = true
            showNetworkLost()
            return
        }

        loadingID = id
        phase = .loading
        hideControls()
        cancelControlsAutoHide()
        startLoadingTimeout(id: id)

        let item = AVPlayerItem(asset: StreamRequestBuilder.asset(for: url))
        item.preferredPeakBitRate = qualityBitRate
        let player = AVPlayer(playerItem: item)
        player.volume = 1
        player.isMuted = isMuted
        self.player = player

        observe(player, item: item, id: id)
        addPeriodicTimeObserver(to: player)
        player.rate = playbackRate
    }

    /// Stops playback and returns to the idle state (leaving the screen, paywall …).
    func cleanup() {
        onPlaybackStopped?()
        tearDownPlayer()
        player = nil
        isPlaying = false
        progress = 0
        elapsedText = "--:--"
        remainingText = "--:--"
        loadingID = nil
        phase = .idle
        hideControls()
        cancelLoadingTimeout()
        cancelControlsAutoHide()
    }

    /// Like `cleanup()` but keeps the last request so it can be retried.
    func stopKeepingRequest() {
        cleanup()
        showsPreview = true
    }

    /// Plays the current request again (after the paywall or a network drop).
    func reload() {
        guard let request = currentRequest else { return }
        load(url: request.url, id: request.id)
    }

    // MARK: - Playback controls

    func togglePlayback() {
        guard !isLocked, let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
            showControls(autoHide: false)
        } else {
            player.rate = playbackRate
            isPlaying = true
            showControls(autoHide: true)
        }
    }

    /// Resumes a paused stream (after a purchase).
    func resume() {
        guard let player else { return }
        player.rate = playbackRate
        isPlaying = true
        showControls(autoHide: true)
    }

    /// Jumps `seconds` forward (or back when negative).
    func seek(by seconds: Double) {
        guard !isLocked, let player else { return }
        let current = player.currentTime().seconds
        guard current.isFinite else { return }
        var target = max(current + seconds, 0)
        if let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 {
            target = min(target, duration)
        }
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        showControls(autoHide: isPlaying)
    }

    func seek(toFraction fraction: Double) {
        guard !isLocked,
              let player,
              let duration = player.currentItem?.duration.seconds,
              duration.isFinite, duration > 0 else { return }
        let target = CMTime(seconds: duration * max(0, min(fraction, 1)), preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        showControls(autoHide: isPlaying)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if player?.timeControlStatus == .playing {
            player?.rate = rate
        }
        showControls(autoHide: isPlaying)
    }

    func setQualityBitRate(_ bitRate: Double) {
        qualityBitRate = bitRate
        player?.currentItem?.preferredPeakBitRate = bitRate
        showControls(autoHide: isPlaying)
    }

    func setAspect(_ option: DetailXtreamAspectRatioOption) {
        aspect = option
        showControls(autoHide: isPlaying)
    }

    // MARK: - Audio & brightness

    func toggleMute() {
        guard !isLocked else { return }
        isMuted.toggle()
        player?.isMuted = isMuted
        showControls(autoHide: isPlaying)
    }

    func setVolume(_ newVolume: Float) {
        lastVolume = max(0, min(newVolume, 1))
        volume = lastVolume
        player?.volume = 1
        // The system volume is what really changes; the slider inside MPVolumeView drives it.
        systemVolumeSlider?.setValue(lastVolume, animated: false)
        systemVolumeSlider?.sendActions(for: .valueChanged)
        isMuted = lastVolume == 0
        player?.isMuted = isMuted
        showControls(autoHide: isPlaying)
    }

    /// Volume of the last tap on the speaker icon: toggles between loud and quiet.
    func toggleVolumePreset() {
        guard !isLocked else { return }
        setVolume(lastVolume < 0.5 ? 1 : 0.35)
    }

    func setBrightness(_ value: CGFloat) {
        UIScreen.main.brightness = max(0, min(value, 1))
        brightness = UIScreen.main.brightness
        showControls(autoHide: isPlaying)
    }

    func adjustBrightness(by delta: CGFloat) {
        guard !isLocked else { return }
        setBrightness(UIScreen.main.brightness + delta)
    }

    func toggleBrightnessPreset() {
        guard !isLocked else { return }
        setBrightness(UIScreen.main.brightness >= 0.95 ? 0.25 : UIScreen.main.brightness + 0.25)
    }

    func adjustVolume(by delta: Float) {
        guard !isLocked else { return }
        setVolume(lastVolume + delta)
    }

    /// Connects the hidden `MPVolumeView` hosted by the video surface.
    func attach(volumeView: MPVolumeView) {
        systemVolumeSlider = volumeView.subviews.compactMap { $0 as? UISlider }.first
        DispatchQueue.main.async { [weak self, weak volumeView] in
            guard let volumeView else { return }
            self?.systemVolumeSlider = volumeView.subviews.compactMap { $0 as? UISlider }.first
        }
    }

    // MARK: - Controls visibility

    func didTapPlayerArea() {
        guard !isLocked, player != nil, phase == .ready else { return }
        showControls(autoHide: isPlaying)
    }

    func showControls(autoHide: Bool) {
        guard !isLocked, player != nil, phase == .ready else { return }
        cancelControlsAutoHide()
        isControlsVisible = true
        if autoHide {
            scheduleControlsAutoHide()
        }
    }

    func toggleLock() {
        isLocked.toggle()
        cancelControlsAutoHide()
        isControlsVisible = false
        if !isLocked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self else { return }
                showControls(autoHide: isPlaying)
            }
        }
    }

    func toggleFullscreen() {
        guard !isLocked else { return }
        setFullscreen(!isFullscreen)
    }

    func setFullscreen(_ fullscreen: Bool) {
        guard isFullscreen != fullscreen else { return }
        isFullscreen = fullscreen
        DeviceOrientation.setLandscape(fullscreen)
        showControls(autoHide: isPlaying)
    }

    // MARK: - Private: observers

    private func observe(_ player: AVPlayer, item: AVPlayerItem, id: String) {
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async { self?.handle(status: item.status, id: id) }
        }
        keepUpObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            guard item.isPlaybackLikelyToKeepUp else { return }
            DispatchQueue.main.async { self?.markReady(id: id) }
        }
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let playing = player.timeControlStatus == .playing
                isPlaying = playing
                if playing {
                    markReady(id: id)
                    onPlaybackStarted?()
                } else {
                    onPlaybackStopped?()
                }
            }
        }
    }

    private func addPeriodicTimeObserver(to player: AVPlayer) {
        periodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func updateProgress() {
        guard let player else {
            progress = 0
            elapsedText = "--:--"
            remainingText = "--:--"
            return
        }
        let current = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0
        elapsedText = Self.timeText(current)
        guard current.isFinite, duration.isFinite, duration > 0 else {
            progress = 0
            remainingText = "--:--"
            return
        }
        progress = max(0, min(current / duration, 1))
        remainingText = Self.timeText(max(duration - current, 0))
    }

    private static func timeText(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func handle(status: AVPlayerItem.Status, id: String) {
        guard loadingID == id else { return }
        switch status {
        case .readyToPlay:
            player?.rate = playbackRate
        case .failed:
            failLoad(id: id)
        default:
            break
        }
    }

    private func observeSystemVolume() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        syncSystemVolume(session.outputVolume, shouldUnmute: false)
        outputVolumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, _ in
            DispatchQueue.main.async { self?.syncSystemVolume(session.outputVolume, shouldUnmute: true) }
        }
    }

    private func syncSystemVolume(_ newVolume: Float, shouldUnmute: Bool) {
        let clamped = max(0, min(newVolume, 1))
        let didChange = abs(lastVolume - clamped) > 0.001
        lastVolume = clamped
        volume = clamped
        player?.volume = 1
        if clamped == 0 {
            isMuted = true
            player?.isMuted = true
        } else if shouldUnmute && didChange {
            isMuted = false
            player?.isMuted = false
        }
    }

    private func observeNetwork() {
        NetworkOverlayManager.shared.isConnectedSubject
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConnected in
                guard let self, isActive else { return }
                if isConnected {
                    handleNetworkRestored()
                } else {
                    handleNetworkLost()
                }
            })
            .disposed(by: bag)
    }

    private func handleNetworkLost() {
        guard currentRequest != nil else { return }
        shouldReconnectWhenNetworkRestores = true
        onPlaybackStopped?()
        player?.pause()
        cancelLoadingTimeout()
        cancelControlsAutoHide()
        showNetworkLost()
    }

    private func handleNetworkRestored() {
        guard shouldReconnectWhenNetworkRestores else { return }
        shouldReconnectWhenNetworkRestores = false
        reload()
    }

    private func showNetworkLost() {
        loadingID = nil
        phase = .networkLost
        hideControls()
    }

    // MARK: - Private: loading state

    private func markReady(id: String) {
        guard loadingID == id else { return }
        showsPreview = false
        loadingID = nil
        phase = .ready
        cancelLoadingTimeout()
        showControls(autoHide: player?.timeControlStatus == .playing)
    }

    private func failLoad(id: String) {
        onPlaybackStopped?()
        guard loadingID == nil || loadingID == id else { return }
        tearDownPlayer()
        player = nil
        isPlaying = false
        loadingID = nil
        phase = .failed
        showsPreview = true
        hideControls()
        cancelLoadingTimeout()
        cancelControlsAutoHide()
        onLoadFailed?(id)
    }

    private func startLoadingTimeout(id: String) {
        cancelLoadingTimeout()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, loadingID == id else { return }
            failLoad(id: id)
        }
        loadingTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + loadTimeout, execute: workItem)
    }

    private func cancelLoadingTimeout() {
        loadingTimeoutWorkItem?.cancel()
        loadingTimeoutWorkItem = nil
    }

    // MARK: - Private: controls

    private func hideControls() {
        isControlsVisible = false
    }

    private func scheduleControlsAutoHide() {
        cancelControlsAutoHide()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, player?.timeControlStatus == .playing else { return }
            isControlsVisible = false
        }
        controlsHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + controlsAutoHideDelay, execute: workItem)
    }

    private func cancelControlsAutoHide() {
        controlsHideWorkItem?.cancel()
        controlsHideWorkItem = nil
    }

    private func tearDownPlayer() {
        statusObservation?.invalidate()
        statusObservation = nil
        keepUpObservation?.invalidate()
        keepUpObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let periodicTimeObserver {
            player?.removeTimeObserver(periodicTimeObserver)
            self.periodicTimeObserver = nil
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }
}
