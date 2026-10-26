//
//  AppDelegate.swift
//  I340_IPTV
//
//  Created by HaoLK on 03/12/2020.
//

import AdsDebugKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let dependencies = AppDependencies.make()
    /// Orientations the app allows right now (fullscreen video asks for landscape).
    var orientationMask: UIInterfaceOrientationMask = .portrait

    let systemEventsHandler = SystemEventsHandler()
    let pushNotificationsHandler = PushNotificationsHandler()

    static func share() -> AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        dependencies.build()
        UIViewController.installPresentationMonitoring()
        _ = NetworkOverlayManager.shared

        let telemetryConfig = AdTelemetryConfiguration(allAdIDs: { Configs.AdvertisementID.allCases })
        AdTelemetry.initialize(telemetryConfig)
        pushNotificationsHandler.start()
        // Support multiple languages
        systemEventsHandler.setupLocalize()
        windowConfig()
        systemEventsHandler.setupFirebase()
        systemEventsHandler.setupCache()
        systemEventsHandler.setupIAP()
        systemEventsHandler.setupMeta(application, didFinishLaunchingWithOptions: launchOptions)
        UserDefaultManager.shared().isSelectedLanguage = false
        systemEventsHandler.setupSiren()
        systemEventsHandler.setupAds()

        return true
    }

    /// (Re)builds the window root: at launch and when the language changes.
    func windowConfig(isFromLanguageSetting: Bool = false) {
        window = UIWindow(frame: UIScreen.main.bounds)
        let root = AppEnvironment.shared.rootView(startsFromLanguageSetting: isFromLanguageSetting)
        window?.rootViewController = RootHostingController(rootView: root)
        window?.makeKeyAndVisible()
    }

    // MARK: - System events

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        orientationMask
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        systemEventsHandler.open(application, url: url)
        return true
    }

    // MARK: - Push notifications

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushNotificationsHandler.didReceiveRemoteNotification(userInfo: userInfo, completionHandler: completionHandler)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        pushNotificationsHandler.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        pushNotificationsHandler.didFailToRegisterForRemoteNotifications(error: error)
    }
}
