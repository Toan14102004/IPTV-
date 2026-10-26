//
//  SplashViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import RxSwift
import SwiftUI

extension SplashView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published var progress: Double = 0

        /// Subscribed users do not see the "may contain ads" hint and progress bar.
        let isAdHintHidden = IAPHelper.shared().isSubscribed()

        private let isFromLanguageSetting: Bool
        private let appState: Store<AppState>
        private let bag = DisposeBag()

        private var countdownTimer: Timer?
        private var secondsRemaining: Int = 10
        private let delayTimeSplash: TimeInterval = 10
        private var hasGatherConsent = false
        private var isStopTimer = false
        private var lastIsNetworkConnectedState = NetworkOverlayManager.shared.isConnected
        private var isAdShowed = false
        private var hasStarted = false

        init(
            isFromLanguageSetting: Bool,
            appState: Store<AppState> = AppEnvironment.shared.container.appState
        ) {
            self.isFromLanguageSetting = isFromLanguageSetting
            self.appState = appState
        }

        deinit {
            countdownTimer?.invalidate()
        }

        // MARK: - Lifecycle

        func onAppear() {
            // Same rule the UIKit splash had: no app-open ad while the splash is on screen.
            AdsManager.shared.isAppOpenAdSuppressed = true

            if !hasStarted {
                hasStarted = true
                start()
            }
            if !isStopTimer && countdownTimer == nil && !isFromLanguageSetting {
                createTimer()
            }
        }

        func onDisappear() {
            AdsManager.shared.isAppOpenAdSuppressed = false
            countdownTimer?.invalidate()
            countdownTimer = nil
        }

        private func start() {
            if !isFromLanguageSetting {
                observeNetworkAndSetupConsent()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.goToNextScreen()
                }
            }
        }

        // MARK: - Network

        private func observeNetworkAndSetupConsent() {
            NetworkOverlayManager.shared.isConnectedSubject
                .distinctUntilChanged()
                .skip(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] isConnected in
                    guard let self else { return }
                    if isConnected != lastIsNetworkConnectedState && !isAdShowed {
                        if isConnected {
                            AppDelegate.share().windowConfig()
                        } else if let timer = countdownTimer {
                            stopTimer(timer)
                        }
                        lastIsNetworkConnectedState = isConnected
                    }
                })
                .disposed(by: bag)
        }

        // MARK: - Ads

        private func gatherConsentIfNeeded(onCompleted: @escaping () -> Void) {
            if IAPHelper.shared().isSubscribed() {
                onCompleted()
                return
            }
            guard let presenter = UIApplication.shared.topMostViewController else {
                onCompleted()
                return
            }

            AdsManager.shared.gatherConsent(
                from: presenter,
                onCompletion: { [weak self] _ in
                    self?.hasGatherConsent = true
                    onCompleted()
                },
                isHighFloor: true
            )
        }

        private func preloadAds() {
            AdsManager.shared.preloadNativeAd(.ADSNativeLanguageAds2FID, autoReload: true)
            AdsManager.shared.preloadNativeAd(.ADSNativeLanguageAdsMFID)
            AdsManager.shared.preloadNativeAd(.ADSNativeLanguageAdsID)

            AdsManager.shared.preloadNativeAd(.ADSNativeIntroFirst2FID)
            AdsManager.shared.preloadNativeAd(.ADSNativeIntroFirstMFID)
            AdsManager.shared.preloadNativeAd(.ADSNativeIntroFirstID)

            AdsManager.shared.preloadNativeAd(.ADSNativeIntroThird2FID)
            AdsManager.shared.preloadNativeAd(.ADSNativeIntroThirdMFID)
            AdsManager.shared.preloadNativeAd(.ADSNativeIntroThirdID)

            AdsManager.shared.preloadNativeAd(.ADSNativeFullScreen2FID)
            AdsManager.shared.preloadNativeAd(.ADSNativeFullScreenMFID)
            AdsManager.shared.preloadNativeAd(.ADSNativeFullScreenID)
        }

        private func showOpenInterstitialHighAd(
            onAdShowed: @escaping () -> Void,
            onAdClosed: @escaping (Bool) -> Void
        ) {
            guard let presenter = UIApplication.shared.topMostViewController else { return }
            AdsManager.shared.openInterstitialAd2FUtils.showAd(
                from: presenter,
                onAdsShowed: onAdShowed,
                onAdsClosed: onAdClosed
            )
        }

        private func showOpenInterstitialHighDupAd(
            onAdShowed: @escaping () -> Void,
            onAdClosed: @escaping (Bool) -> Void
        ) {
            guard let presenter = UIApplication.shared.topMostViewController else { return }
            AdsManager.shared.openInterstitialAdMFUtils.showAd(
                from: presenter,
                onAdsShowed: onAdShowed,
                onAdsClosed: onAdClosed
            )
        }

        // MARK: - Timer

        private func createTimer() {
            if isStopTimer || countdownTimer != nil || !NetworkOverlayManager.shared.isConnected { return }

            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else {
                    timer.invalidate()
                    return
                }
                tick(timer)
            }
        }

        private func tick(_ timer: Timer) {
            secondsRemaining -= 1

            if IAPHelper.shared().isSubscribed() {
                if secondsRemaining == 9 {
                    progress = 1
                    createTimer()
                } else if secondsRemaining == 8 {
                    stopTimer(timer)
                    goToNextScreen()
                }
                return
            }

            let elapsed = delayTimeSplash - TimeInterval(secondsRemaining)
            progress = max(0, min(1, elapsed / delayTimeSplash))

            if (RemoteConfigHelper.shared.remoteConfigFetched || secondsRemaining < 5) && !hasGatherConsent {
                pauseTimer(timer)
                gatherConsentIfNeeded { [weak self] in
                    self?.isStopTimer = false
                    DispatchQueue.main.async {
                        self?.createTimer()
                    }
                }
                return
            }

            if AdsManager.shared.openInterstitialAd2FUtils.isAdAvailable() {
                stopTimer(timer)
                showOpenInterstitialHighAd(
                    onAdShowed: { [weak self] in
                        self?.isAdShowed = true
                        self?.preloadAds()
                    },
                    onAdClosed: { [weak self] isAdClosed in
                        self?.isStopTimer = isAdClosed
                        if isAdClosed {
                            self?.goToNextScreen()
                        }
                    }
                )
                return
            }

            if secondsRemaining <= 2 && AdsManager.shared.openInterstitialAdMFUtils.isAdAvailable() {
                stopTimer(timer)
                showOpenInterstitialHighDupAd(
                    onAdShowed: { [weak self] in
                        self?.isAdShowed = true
                        self?.preloadAds()
                    },
                    onAdClosed: { [weak self] isAdClosed in
                        self?.isStopTimer = isAdClosed
                        if isAdClosed {
                            self?.goToNextScreen()
                        }
                    }
                )
                return
            }

            if secondsRemaining <= 0 {
                stopTimer(timer)

                if !hasGatherConsent {
                    gatherConsentIfNeeded { [weak self] in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self?.goToGetStartScreen()
                        }
                    }
                } else {
                    goToGetStartScreen()
                }
            }
        }

        private func pauseTimer(_ timer: Timer) {
            isStopTimer = true
            timer.invalidate()
            countdownTimer = nil
        }

        private func stopTimer(_ timer: Timer) {
            progress = 1
            isStopTimer = true
            timer.invalidate()
            countdownTimer = nil
        }

        // MARK: - Navigation

        private func goToNextScreen() {
            DispatchQueue.main.async { [weak self] in
                self?.progress = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.openNextFlow()
                }
            }
        }

        private func goToGetStartScreen() {
            DispatchQueue.main.async { [weak self] in
                self?.progress = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.openNextFlow()
                }
            }
        }

        private func openNextFlow() {
            if isFromLanguageSetting {
                appState[\.route] = .content
            } else {
                // Get Started is shown once, on the first launch.
                appState[\.route] = UserDefaultManager.shared().hasSeenGetStarted ? .language : .getStarted
            }
        }
    }
}
