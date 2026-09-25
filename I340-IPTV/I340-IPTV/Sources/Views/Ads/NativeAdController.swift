//
//  NativeAdController.swift
//  I340_IPTV
//

import Combine
import GoogleMobileAds
import RxCocoa
import RxSwift
import UIKit

/// Loads and periodically refreshes one native ad shown by a UIKit `NativeAdViewProtocol` view.
///
/// It is the SwiftUI counterpart of `BaseNative2FVC` + `BaseVC`'s refresh logic: priority
/// 2F → MF → normal, reload every `reloadDelay` seconds while the screen is really visible.
final class NativeAdController: ObservableObject {
    struct Config {
        let adIdNormal: Configs.AdvertisementID
        var adId2F: Configs.AdvertisementID?
        var adIdMF: Configs.AdvertisementID?
        var isEnabled: Bool = true
    }

    /// False when this screen never shows an ad (subscribed user or disabled by remote config).
    let isAvailable: Bool
    /// True while there is nothing to show (not loaded yet, the load failed or ads are off).
    @Published private(set) var isCollapsed: Bool

    let adView: NativeAdViewProtocol

    private let config: Config
    private let reloadDelay: TimeInterval = 5
    private var lastLoadTime: TimeInterval = 0
    private var isAppeared = false
    private var hasSetupObservers = false
    private var timerDisposable: Disposable?
    private let resumeTrigger = PublishRelay<String>()
    private let bag = DisposeBag()

    init(config: Config, makeAdView: () -> NativeAdViewProtocol) {
        self.config = config
        adView = makeAdView()
        isAvailable = !IAPHelper.shared().isSubscribed() && config.isEnabled
        adView.isHidden = !isAvailable
        isCollapsed = !isAvailable || adView.isGone
    }

    deinit {
        timerDisposable?.dispose()
        adView.cancelPendingLoad()
    }

    // MARK: - Lifecycle

    func appear() {
        isAppeared = true
        setupObserversIfNeeded()
        resumeTrigger.accept("viewDidAppear")
    }

    func disappear() {
        isAppeared = false
        stopTimer()
    }

    // MARK: - Observers

    private func setupObserversIfNeeded() {
        guard !hasSetupObservers else { return }
        hasSetupObservers = true
        let scheduler = MainScheduler.instance

        resumeTrigger
            .debounce(.milliseconds(500), scheduler: scheduler)
            .subscribe(onNext: { [weak self] reason in self?.tryResume(reason: reason) })
            .disposed(by: bag)

        NetworkOverlayManager.shared.isConnectedSubject
            .distinctUntilChanged().skip(1)
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] isConnected in
                if isConnected {
                    self?.resumeTrigger.accept("Network Back")
                } else {
                    self?.stopTimer()
                }
            })
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] _ in self?.stopTimer() })
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] _ in
                guard let self, isAppeared else { return }
                resumeTrigger.accept("App Foreground")
            })
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(UIWindow.didBecomeKeyNotification)
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] notification in
                guard let self, let window = notification.object as? UIWindow else { return }
                // The debug overlay must not change the ads state.
                if let owner = adView.owningViewController, owner.isDebugWindow(window) { return }
                if window === adView.window {
                    resumeTrigger.accept("Window Become Key")
                }
            })
            .disposed(by: bag)

        PresentationCenter.shared.stackDidChange
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] sourceWindow in
                guard let self else { return }
                if let sourceWindow, adView.owningViewController?.isDebugWindow(sourceWindow) == true { return }
                // Immediate checks are wrong during transitions, re-evaluate a bit later.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if self.shouldRun() {
                        self.resumeTrigger.accept("Stack Change")
                    } else {
                        self.stopTimer()
                    }
                }
            })
            .disposed(by: bag)
    }

    // MARK: - Refresh loop

    private func tryResume(reason: String) {
        guard Configs.Advertisement.canRequestAndShowAds else {
            stopTimer()
            return
        }
        guard shouldRun() else { return }

        let passed = Date().timeIntervalSince1970 - lastLoadTime
        if passed >= reloadDelay {
            loadAndLoop()
        } else {
            startTimer(duration: reloadDelay - passed)
        }
    }

    private func loadAndLoop() {
        guard shouldRun() else { return }
        lastLoadTime = Date().timeIntervalSince1970
        loadAd()
        startTimer(duration: reloadDelay)
    }

    private func shouldRun() -> Bool {
        guard Configs.Advertisement.canRequestAndShowAds, config.isEnabled else {
            stopTimer()
            return false
        }
        if IAPHelper.shared().isSubscribed() {
            stopTimer()
            return false
        }
        guard NetworkOverlayManager.shared.isConnected else { return false }
        guard isAppeared, isOnScreen() else { return false }
        return !AdsManager.shared.getIsPresentingFullScreenAd()
    }

    private func startTimer(duration: TimeInterval) {
        stopTimer()
        let milliseconds = max(0, Int(duration * 1000))
        timerDisposable = Observable<Int>.timer(.milliseconds(milliseconds), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self, shouldRun() else { return }
                loadAndLoop()
            })
    }

    private func stopTimer() {
        timerDisposable?.dispose()
        timerDisposable = nil
    }

    /// Same rules as `BaseVC.isVisibleController`: front-most non-debug window and not covered.
    private func isOnScreen() -> Bool {
        guard let owner = adView.owningViewController, owner.isViewLoaded,
              let window = adView.window,
              let frontWindow = owner.frontNonDebugWindow(in: window.windowScene),
              frontWindow === window,
              let root = window.rootViewController else { return false }

        let topMost = root.fx_topMost()
        return topMost === owner || owner.isSelfOrAncestor(of: topMost) || topMost.isSelfOrAncestor(of: owner)
    }

    // MARK: - Loading

    private func loadAd() {
        guard Configs.Advertisement.canRequestAndShowAds, !IAPHelper.shared().isSubscribed(), config.isEnabled else {
            adView.gone()
            isCollapsed = true
            return
        }

        if let preloaded = availablePreloadedAd() {
            adView.configure(with: preloaded)
        } else {
            adView.loadAndConfig(adId: config.adIdNormal) { [weak self] isSuccess in
                guard let self else { return }
                isCollapsed = !isSuccess || adView.isGone
            }
        }
    }

    /// Priority: 2F (high floor) → MF (mid floor) → normal.
    ///
    /// A plain loop on purpose: fetching a preloaded ad *removes* it from the pool, and
    /// `lazy.compactMap { … }.first` runs the closure twice (once to find the element, once to
    /// read it), so the second run found nothing and trapped.
    private func availablePreloadedAd() -> NativeAd? {
        for adId in [config.adId2F, config.adIdMF, config.adIdNormal].compactMap({ $0 }) {
            if let ad = AdsManager.shared.getPreloadNativeAdById(adId) { return ad }
        }
        return nil
    }
}
