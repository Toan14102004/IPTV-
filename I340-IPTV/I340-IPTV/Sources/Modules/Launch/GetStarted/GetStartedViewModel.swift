//
//  GetStartedViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation

extension GetStartedView {
    final class ViewModel: ObservableObject {
        private let appState: Store<AppState>

        init(appState: Store<AppState> = AppEnvironment.shared.container.appState) {
            self.appState = appState
        }

        // MARK: - Texts

        let title = "get_started_title".localized
        let message = "get_started_message".localized
        let buttonTitle = "inapp_get_started".localized

        // MARK: - Actions

        func didTapGetStarted() {
            UserDefaultManager.shared().hasSeenGetStarted = true
            appState[\.route] = .language
        }
    }
}
