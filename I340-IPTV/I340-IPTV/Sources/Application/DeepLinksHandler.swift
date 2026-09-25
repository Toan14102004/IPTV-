//
//  DeepLinksHandler.swift
//  I340_IPTV
//

import AppsFlyerLib
import Foundation

/// AppsFlyer deep links and install attribution.
final class DeepLinksHandler: NSObject {
    private(set) var conversionData: [AnyHashable: Any]?
}

// MARK: - DeepLinkDelegate

extension DeepLinksHandler: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        switch result.status {
        case .notFound:
            NSLog("[AFSDK] Deep link not found")
            return
        case .failure:
            print("Error %@", result.error!)
            return
        case .found:
            NSLog("[AFSDK] Deep link found")
        }

        guard let deepLink = result.deepLink else {
            NSLog("[AFSDK] Could not extract deep link object")
            return
        }

        NSLog("[AFSDK] DeepLink data is: \(deepLink.toString())")
        NSLog(deepLink.isDeferred == true ? "[AFSDK] This is a deferred deep link" : "[AFSDK] This is a direct deep link")

        guard deepLink.deeplinkValue != nil else {
            print("Could not extract deep_link_value from deep link object")
            return
        }

        // Every deep link opens the app from its start.
        AppDelegate.share().windowConfig()
    }
}

// MARK: - AppsFlyerLibDelegate

extension DeepLinksHandler: AppsFlyerLibDelegate {
    /// Organic / non-organic installation.
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        conversionData = data
        print("onConversionDataSuccess data:")
        for (key, value) in data {
            print(key, ":", value)
        }
    }

    func onConversionDataFail(_ error: Error) {
        NSLog("[AFSDK] \(error)")
    }
}
