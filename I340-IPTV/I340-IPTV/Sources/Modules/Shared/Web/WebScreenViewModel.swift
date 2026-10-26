//
//  WebScreenViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation

extension WebScreenView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var isLoading = true

        let urlString: String
        private let onClose: () -> Void

        init(urlString: String, onClose: @escaping () -> Void) {
            self.urlString = urlString
            self.onClose = onClose
        }

        var errorTitle: String { "error".localized }
        var errorMessage: String { "generic_error_message".localized }

        func didStartLoading() {
            isLoading = true
        }

        func didFinishLoading() {
            isLoading = false
        }

        func didFailLoading() {
            isLoading = false
            coordinator.alert = .loadFailed
        }

        func didTapClose() {
            onClose()
        }
    }
}
