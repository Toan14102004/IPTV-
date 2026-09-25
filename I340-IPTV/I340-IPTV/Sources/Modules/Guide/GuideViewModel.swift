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

        private let onBack: () -> Void

        init(onBack: @escaping () -> Void) {
            self.onBack = onBack
        }

        func didTapBack() {
            InterstitialGuard.perform(onBack)
        }

        func stepTitle(_ number: Int) -> String {
            String(format: "guide_step_format".localized, number)
        }
    }
}
