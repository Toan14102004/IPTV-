//
//  NoConnectionViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import UIKit

extension NoConnectionView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()

        func didTapTryAgain() {
            if !NetworkOverlayManager.shared.isConnected {
                coordinator.alert = .stillOffline
            }
        }

        func didTapGoToSettings() {
            UIApplication.openAppSettings { _ in }
        }
    }
}
