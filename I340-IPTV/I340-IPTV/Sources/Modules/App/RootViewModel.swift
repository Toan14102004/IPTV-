//
//  RootViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension RootView {
    class ViewModel: ObservableObject {
        @Published var path = FlowPath()
        @Published var route: AppRoute
        @Published var coordinator = Coordinator()

        private let cancelBag = CancelBag()

        init(container: DIContainer, startsFromLanguageSetting: Bool = false) {
            let initialRoute = AppRoute.splash(isFromLanguageSetting: startsFromLanguageSetting)
            container.appState[\.route] = initialRoute
            route = initialRoute

            container.appState.updates(for: \.route)
                .sink { [weak self] newRoute in
                    guard let self, route != newRoute else { return }
                    route = newRoute
                }
                .store(in: cancelBag)

            container.appState.updates(for: \.path)
                .sink { [weak self] newPath in
                    guard let self else { return }
                    if path != newPath {
                        path = newPath
                    }
                }
                .store(in: cancelBag)
        }
    }
}
