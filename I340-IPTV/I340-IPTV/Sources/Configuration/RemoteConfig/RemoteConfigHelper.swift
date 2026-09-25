//
//  RemoteConfigHelper.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import Foundation
import FirebaseRemoteConfig

class RemoteConfigHelper {
    static let shared = RemoteConfigHelper.init()
    var remoteConfigFetched = false

    private var isFetching = false
    private var hasRegisteredRealtimeListener = false
    private var pendingCompletions: [() -> Void] = []
    private var remoteConfig: RemoteConfig? = nil
    
    func fetchConfig(forceRefresh: Bool = false, _ onCompleted: (() -> Void)? = nil) {
        if remoteConfigFetched && !forceRefresh {
            EventTrackingHelper.shared.retryPendingPredictPurchases()
            onCompleted?()
            return
        }

        if let onCompleted = onCompleted {
            pendingCompletions.append(onCompleted)
        }

        guard !isFetching else { return }
        isFetching = true

        remoteConfig = RemoteConfig.remoteConfig()
        guard let remoteConfig = remoteConfig else {
            completeFetchCallbacks()
            return
        }
        
        let settings = RemoteConfigSettings()
#if DEBUG
        settings.minimumFetchInterval = Configs.Network.remoteConfigMinimumFetchInterval          // always hit server when you call fetch in DEBUG
#else
        settings.minimumFetchInterval = Configs.Network.remoteConfigMinimumFetchInterval
#endif
        remoteConfig.configSettings = settings
        
        remoteConfig.setDefaults(getRemoteConfigDefaults())

        registerRealtimeUpdatesIfNeeded(on: remoteConfig)
        
        let completeFetch: (RemoteConfigFetchAndActivateStatus?, Error?) -> Void = { [weak self] status, error in
            guard let self = self else { return }
            if let error = error {
                print("RemoteConfig update error: \(error)")
                self.completeFetchCallbacks()
                return
            }

            self.remoteConfigFetched = true
            if let status = status {
                print("RemoteConfig initial fetch: \(status)")
            }
            EventTrackingHelper.shared.retryPendingPredictPurchases()
            self.completeFetchCallbacks()
        }

        if forceRefresh {
            remoteConfig.fetch(withExpirationDuration: 0) { _, error in
                guard error == nil else {
                    completeFetch(nil, error)
                    return
                }
                remoteConfig.activate { _, activationError in
                    completeFetch(nil, activationError)
                }
            }
        } else {
            remoteConfig.fetchAndActivate { status, error in
                completeFetch(status, error)
            }
        }
    }

    private func completeFetchCallbacks() {
        isFetching = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0() }
    }

    private func registerRealtimeUpdatesIfNeeded(on remoteConfig: RemoteConfig) {
        guard !hasRegisteredRealtimeListener else { return }
        hasRegisteredRealtimeListener = true

        // Realtime updates (requires FCM setup)
        remoteConfig.addOnConfigUpdateListener { update, error in
            if let error = error {
                print("RemoteConfig update error: \(error)")
                return
            }
            guard let update = update else { return }
            print("RemoteConfig keys changed: \(update.updatedKeys)")
            
            remoteConfig.fetchAndActivate { status, error in
                if let error = error {
                    print("RemoteConfig update error: \(error)")
                    return
                }
                print("RemoteConfig fetchAndActivate after push: \(status)")
                EventTrackingHelper.shared.retryPendingPredictPurchases()
            }
        }
    }
    
    // MARK: - New methods with String key (primary)
    
    func getStringValue(key: String) -> String {
        return remoteConfig?.configValue(forKey: key).stringValue ?? ""
    }
    
    func getBoolValue(key: String, defaultValue: Bool) -> Bool {
        return remoteConfig?.configValue(forKey: key).boolValue ?? defaultValue
    }
    
    func getIntValue(key: String, defaultValue: Int) -> Int {
        return remoteConfig?.configValue(forKey: key).numberValue.intValue ?? defaultValue
    }

    func getDoubleValue(key: String, defaultValue: Double) -> Double {
        return remoteConfig?.configValue(forKey: key).numberValue.doubleValue ?? defaultValue
    }
}

