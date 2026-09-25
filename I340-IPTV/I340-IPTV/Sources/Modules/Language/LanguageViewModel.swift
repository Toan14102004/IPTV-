//
//  LanguageViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension LanguageView {
    /// Where the screen is shown from.
    enum Context {
        /// First launch: choosing continues to the onboarding.
        case onboarding
        /// Opened from Settings (presented by UIKit); `onClose` dismisses it.
        case settings(onClose: () -> Void)
    }

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var languages: [Language] = ViewModel.supportedLanguages
        @Published private(set) var isTooltipHidden = false
        @Published var toast: String?

        let context: Context
        private let appState: Store<AppState>

        var isOpenApp: Bool {
            if case .onboarding = context { return true }
            return false
        }

        private var selectedLanguage: Language? { languages.first(where: \.isSelected) }

        init(
            context: Context,
            appState: Store<AppState> = AppEnvironment.shared.container.appState
        ) {
            self.context = context
            self.appState = appState

            if !UserDefaultManager.shared().firstSelectedLanguage {
                let appLanguage = UserDefaultManager.shared().appLanguage
                if let index = languages.firstIndex(where: { $0.languageCode.code == appLanguage }) {
                    select(at: index)
                }
            }
            isTooltipHidden = selectedLanguage != nil
        }

        // MARK: - Actions

        func select(_ language: Language) {
            guard let index = languages.firstIndex(where: { $0.id == language.id }) else { return }
            select(at: index)
            isTooltipHidden = true
        }

        func didTapBack() {
            if case let .settings(onClose) = context {
                onClose()
            }
        }

        func didTapDone() {
            guard selectedLanguage != nil else {
                toast = "please_choose_a_language".localized
                return
            }

            if !UserDefaultManager.shared().isSelectedLanguage {
                applyLanguage()
                UserDefaultManager.shared().isSelectedLanguage = true
                appState[\.route] = .onboard
            } else {
                coordinator.alert = .restartRequired
            }
        }

        func confirmRestart() {
            applyLanguage()
            coordinator.alert = nil
            if case let .settings(onClose) = context {
                onClose()
            }
            AppDelegate.share().windowConfig(isFromLanguageSetting: true)
        }

        func cancelRestart() {
            coordinator.alert = nil
        }

        // MARK: - Private

        private func select(at index: Int) {
            for position in languages.indices {
                languages[position].isSelected = (position == index)
            }
        }

        private func applyLanguage() {
            guard let code = selectedLanguage?.languageCode.code else { return }
            Bundle.setLanguage(lang: code)
            UserDefaultManager.shared().firstSelectedLanguage = false
            UIView.appearance().semanticContentAttribute =
                code == LanguageCode.arabic.code ? .forceRightToLeft : .forceLeftToRight
        }

        private static var supportedLanguages: [Language] {
            [
                (LanguageCode.arabic, "flag_arabic"),
                (.bangla, "flag_bangla"),
                (.chinese, "flag_chinese"),
                (.french, "flag_french"),
                (.german, "flag_german"),
                (.hindi, "flag_hindi"),
                (.japanese, "flag_japanese"),
                (.english, "flag_english"),
                (.portuguese, "flag_portuguese"),
                (.punjabi, "flag_punjabi"),
                (.spanish, "flag_spanish"),
                (.swahili, "flag_swahili")
            ].map { code, flag in
                Language(imgFlag: flag, lbCountry: code.name, isSelected: false, languageCode: code)
            }
        }
    }
}
