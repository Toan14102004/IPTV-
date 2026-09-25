//
//  AppEnvironment.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

struct AppEnvironment {
    static let shared: AppEnvironment = .bootstrap()

    let container: DIContainer
    @Injected private var loadingService: LoadingService
}

extension AppEnvironment {
    static func bootstrap() -> AppEnvironment {
        let appState = Store<AppState>(AppState())
        return AppEnvironment(container: DIContainer(appState: appState))
    }

    /// The SwiftUI root of the app, hosted by `RootHostingController`.
    func rootView(startsFromLanguageSetting: Bool = false) -> some View {
        RootView(viewModel: .init(container: container, startsFromLanguageSetting: startsFromLanguageSetting))
            .modifier(RootViewAppearance())
            .inject(container)
            .environmentObject(loadingService)
    }
}
