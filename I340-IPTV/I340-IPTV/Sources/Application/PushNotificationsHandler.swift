//
//  PushNotificationsHandler.swift
//  I340_IPTV
//

import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Remote (Firebase Cloud Messaging) and local notifications.
final class PushNotificationsHandler: NSObject {
    private let gcmMessageIDKey = "gcm.Message_ID"
    private(set) var isFinishedNotification = false

    /// Called once at launch: receives the notification callbacks.
    func start() {
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Remote notifications

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        logMessageID(in: userInfo)
        print(userInfo)
        completionHandler(.newData)
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    /// Registers for remote notifications again when the user has already allowed them.
    func registerIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Setup

    func setupNotification() {
        configureFirebaseCloudMessaging()

        let time = UserDefaultManager.shared().timeLocalPush

        if time < 7 || time > 21 {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            let hour = Calendar.current.component(.hour, from: Date())
            UserDefaultManager.shared().timeLocalPush = hour
        } else if time != 0 {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let contentNotification = Configs.notificationLocal.contentTrigger.randomElement()!
            self.postLocalNotification(
                title: contentNotification.title,
                content: contentNotification.body,
                attachment: nil,
                timeInterval: Configs.notificationLocal.timeTriggerNoti,
                repeats: true
            )
        }
    }

    func postLocalNotification(title: String, content: String, attachment: URL?, timeInterval: Double, repeats: Bool) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] didAllow, _ in
            self?.isFinishedNotification = true
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }

    // MARK: - Private

    private func configureFirebaseCloudMessaging() {
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
    }

    private func logMessageID(in userInfo: [AnyHashable: Any]) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
    }
}

// MARK: - MessagingDelegate

extension PushNotificationsHandler: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        if Messaging.messaging().fcmToken != nil {
            Messaging.messaging().subscribe(toTopic: "foxcode")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationsHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logMessageID(in: notification.request.content.userInfo)
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        logMessageID(in: userInfo)
        print(userInfo)
        completionHandler()
    }
}
