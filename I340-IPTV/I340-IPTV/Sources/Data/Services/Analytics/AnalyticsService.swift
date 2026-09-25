//
//  AnalyticsService.swift
//  I340_IPTV
//

import FirebaseAnalytics
import Foundation
import GoogleMobileAds

/// Firebase Analytics events every app of this base sends. Attribution SDKs (Adjust, AppsFlyer,
/// Meta, TikTok) stay in `EventTrackingHelper`; this is the product-analytics side.
///
///     AnalyticsService.shared.log(.screenView("Settings"))
///     AnalyticsService.shared.log(.custom("import_playlist", ["source": "m3u"]))
///
/// See `Docs/Analytics.md` for the list of events and their parameters.
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    enum Event {
        /// A screen became visible (`screen_view`).
        case screenView(String)
        /// `purchase`: a verified purchase or renewal.
        case purchase(productID: String, transactionID: String, value: Double, currency: String)
        /// `restore_purchase`.
        case restorePurchase
        /// `ad_impression`: paid event of an ad (AdMob `paidEventHandler`).
        case adImpression(network: String, format: String, unit: String, value: Double, currency: String)
        /// Any other event of the app.
        case custom(String, [String: Any] = [:])
    }

    func log(_ event: Event) {
        let (name, parameters) = payload(for: event)
        Analytics.logEvent(name, parameters: parameters)
        Logger.d("Analytics:", name, parameters ?? [:])
    }

    /// Sets a user property (segments in the Firebase console).
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    // MARK: - Private

    private func payload(for event: Event) -> (String, [String: Any]?) {
        switch event {
        case let .screenView(name):
            return (AnalyticsEventScreenView, [
                AnalyticsParameterScreenName: name,
                AnalyticsParameterScreenClass: name
            ])
        case let .purchase(productID, transactionID, value, currency):
            return (AnalyticsEventPurchase, [
                AnalyticsParameterTransactionID: transactionID,
                AnalyticsParameterValue: value,
                AnalyticsParameterCurrency: currency,
                AnalyticsParameterItemID: productID
            ])
        case .restorePurchase:
            return ("restore_purchase", nil)
        case let .adImpression(network, format, unit, value, currency):
            return (AnalyticsEventAdImpression, [
                AnalyticsParameterAdPlatform: "AdMob",
                AnalyticsParameterAdSource: network,
                AnalyticsParameterAdFormat: format,
                AnalyticsParameterAdUnitName: unit,
                AnalyticsParameterValue: value,
                AnalyticsParameterCurrency: currency
            ])
        case let .custom(name, parameters):
            return (name, parameters.isEmpty ? nil : parameters)
        }
    }
}
