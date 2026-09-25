//
//  SettingsViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension SettingsView {
    enum Option: CaseIterable, Identifiable {
        case language
        case share
        case rateUs
        case contactUs
        case privacyPolicy
        case termsOfUse
        case clearCache

        var id: Self { self }

        var titleKey: String {
            switch self {
            case .language: "settings_language"
            case .share: "settings_share"
            case .rateUs: "settings_rate_us"
            case .contactUs: "settings_contact_us"
            case .privacyPolicy: "settings_privacy_policy"
            case .termsOfUse: "settings_terms_of_use"
            case .clearCache: "settings_clear_cache"
            }
        }

        var fallbackTitle: String {
            switch self {
            case .language: "Language"
            case .share: "Share"
            case .rateUs: "Rate Us"
            case .contactUs: "Contact us"
            case .privacyPolicy: "Privacy Policy"
            case .termsOfUse: "Terms of use"
            case .clearCache: "Clear cache"
            }
        }

        /// Icons drawn in white are tinted to match the red ones.
        var iconTint: Color? {
            self == .clearCache ? Asset.Color.brandRed.color : nil
        }

        var icon: ImageAsset {
            switch self {
            case .language: Asset.Icon.icSettingsLanguage
            case .share: Asset.Icon.icSettingsShare
            case .rateUs: Asset.Icon.icSettingsRate
            case .contactUs: Asset.Icon.icSettingsContact
            case .privacyPolicy: Asset.Icon.icSettingsPrivacy
            case .termsOfUse: Asset.Icon.icSettingsTerms
            case .clearCache: Asset.Icon.icReload
            }
        }
    }

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()
        @Published var toast: String?

        @Injected private var cache: CacheService

        let options = Option.allCases
        private let onBack: () -> Void

        /// `onBack` pops the screen; the caller decides how (UIKit pop today, FlowStack later).
        init(onBack: @escaping () -> Void) {
            self.onBack = onBack
            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        // MARK: - Texts

        func title(for option: Option) -> String {
            localized(option.titleKey, fallback: option.fallbackTitle)
        }

        var screenTitle: String { localized("settings", fallback: "Settings") }
        var upgradePrefix: String { localized("settings_upgrade_prefix", fallback: "Upgrade to ") }
        var upgradePremium: String { localized("settings_upgrade_premium", fallback: "Premium") }
        var upgradeMessage: String {
            localized("settings_upgrade_message", fallback: "Unlock more channels, movies and playlists")
        }

        // MARK: - Actions

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func didTapPremium() {
            AppNavigator.presentPaywall()
        }

        func didSelect(_ option: Option) {
            switch option {
            case .language:
                AppNavigator.present(.language)
            case .share:
                UIApplication.shared.share(items: ["https://apps.apple.com/app/id\(Configs.InfoApp.appId)"])
            case .rateUs:
                navigateToRateScreen()
            case .contactUs:
                contactDeveloper()
            case .privacyPolicy:
                AppNavigator.present(.web(url: Configs.InfoApp.policyUrl))
            case .termsOfUse:
                AppNavigator.present(.web(url: Configs.InfoApp.termOfUseUrl))
            case .clearCache:
                coordinator.alert = .clearCache
            }
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        func confirmClearCache() {
            coordinator.alert = nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                let freed = await cache.totalSize()
                await cache.clearAll()
                let format = localized("settings_cache_cleared", fallback: "Cache cleared (%@)")
                toast = String(format: format, CacheService.formatted(freed))
            }
        }

        // MARK: - Private

        private func contactDeveloper() {
            guard !Configs.InfoApp.email.isEmpty,
                  let url = URL(string: "mailto:\(Configs.InfoApp.email)") else { return }
            UIApplication.shared.open(url)
        }

        private func localized(_ key: String, fallback: String) -> String {
            let value = key.localized
            return value == key || value.isEmpty ? fallback : value
        }
    }
}
