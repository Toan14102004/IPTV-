//
//  SystemEventsHandler.swift
//  I340_IPTV
//

import AdsDebugKit
import FBSDKCoreKit
import Firebase
import FirebaseCore
import Foundation
import PurchaseConnector
import Siren
import StoreKit
import UIKit

/// Start-up of the third-party SDKs and the system events the app forwards to them.
final class SystemEventsHandler: NSObject {
    // MARK: - Launch

    func setupLocalize() {
        if UserDefaultManager.shared().appLanguage.isEmpty {
            Bundle.setLanguage(lang: Utils.getCurrenLanguageCode())
        }

        let appLanguage = UserDefaultManager.shared().appLanguage
        if appLanguage == LanguageCode.arabic.code {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
    }

    func setupFirebase() {
        FirebaseApp.configure()
        RemoteConfigHelper.shared.fetchConfig({})
    }

    func setupCache() {
        CacheService().configureImageCache()
    }

    func setupIAP() {
        IAPHelper.shared().setupIAP(sharedSecret: Configs.InAppPurcharse.iAPSubcriptionSecret)
    }

    func setupAds() {
        AdsManager.shared.configure(numberOfAdsToLoad: Configs.Advertisement.numberOfNativeAdsLoaded)
    }

    func setupSiren() {
        Siren.shared.wail()
    }

    func setupMeta(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        if AdTelemetry.isDebugEnabled() {
            Settings.shared.enableLoggingBehavior(.appEvents)
        }
    }

    // MARK: - Events

    func open(_ app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
}

// MARK: - PurchaseConnector

extension SystemEventsHandler: PurchaseRevenueDataSource, PurchaseRevenueDelegate {
    func didReceivePurchaseRevenueValidationInfo(_ validationInfo: [AnyHashable: Any]?, error: Error?) {
        print("PurchaseRevenueDelegate: \(String(describing: validationInfo))")
        print("PurchaseRevenueDelegate Error: \(String(describing: error?.localizedDescription))")
    }

    func purchaseRevenueAdditionalParameters(
        for products: Set<SKProduct>,
        transactions: Set<SKPaymentTransaction>?
    ) -> [AnyHashable: Any]? {
        ["additionalParameters": ["param1": "value1", "param2": "value2"]]
    }
}
