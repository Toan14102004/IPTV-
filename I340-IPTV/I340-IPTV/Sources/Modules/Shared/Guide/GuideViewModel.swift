//
//  GuideViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension GuideView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var isSubscribed = IAPHelper.shared().isSubscribed()

        private let onBack: () -> Void

        init(onBack: @escaping () -> Void) {
            self.onBack = onBack
            IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
                if isPurchased {
                    DispatchQueue.main.async { self?.isSubscribed = true }
                }
            }
        }

        var premiumAction: (() -> Void)? {
            isSubscribed ? nil : { AppNavigator.presentPaywall() }
        }

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func stepTitle(_ number: Int) -> String {
            String(format: "guide_step_format".localized, number)
        }
    }
}
