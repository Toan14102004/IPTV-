//
//  AppDependencies.swift
//  I340_IPTV
//

import Foundation

/// Services resolved through `@Injected`. Existing singletons are registered as-is so
/// SwiftUI view models can depend on them without knowing about `.shared`.
enum AppDependencies {
    static func make() -> Dependencies {
        Dependencies {
            Dependency { LoadingService() }
            Dependency { NetworkService() }
            Dependency { CacheService() }
            Dependency { IPTVPlaylistManager.shared }
            Dependency { IPTVFavoriteChannelStore.shared }
        }
    }
}
