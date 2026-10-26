//
//  UserDefualtManager.swift
//  I340_IPTV
//
//  Created by HaoLK on 10/12/2020.
//

import Foundation

final class UserDefaultManager {

    enum UserDefaultManagerKey: String {
        case firstLaunchApp
        case firstShowWarningRecord
        case noShowFirstInterAd
        case numberOfLaunches
        case lastVersionPromptedForReview
        case currentCoin
        case isTheFirstTimeInstall
        case haveUpdatedComment
        case HourToPushLocalNoti
        case isRated
        case timeRecord
        case timeDetect
        case appLanguage
        case firstSelectedLanguage
        case isSelectedLanguage
        case accumulatedAdRevenueAmount
        case petName
        case petGender
        case petAge
        case petGoals
        case isShowNativeFull
        case countChatWithAI
        case hasSeenGetStarted
        case favoritePlaylistIDs
        case watchLimitWatchedDuration = "watch_limit_watched_duration"
    }


    var userDefaults: UserDefaults = .standard

    private static var shareInstance: UserDefaultManager = {
        let User = UserDefaultManager.init()
        return User
    }()

    final class func shared() -> UserDefaultManager {
        return shareInstance
    }
    
    var timeLocalPush: Int {
        get { return value(for: UserDefaultManagerKey.HourToPushLocalNoti.rawValue) ?? 0 }
        set { updateDefaults(for: UserDefaultManagerKey.HourToPushLocalNoti.rawValue, value: newValue) }
    }

    var currentCoin: Int {
        get { return value(for: UserDefaultManagerKey.currentCoin.rawValue) ?? 0 }
        set { updateDefaults(for: UserDefaultManagerKey.currentCoin.rawValue, value: newValue) }
    }

    var isTheFirstTimeInstall: Bool {
        get { return value(for: UserDefaultManagerKey.isTheFirstTimeInstall.rawValue) ?? false }
        set { updateDefaults(for: UserDefaultManagerKey.isTheFirstTimeInstall.rawValue, value: newValue) }
    }

    var haveUpdatedComment: Bool {
        get { return value(for: UserDefaultManagerKey.haveUpdatedComment.rawValue) ?? false }
        set { updateDefaults(for: UserDefaultManagerKey.haveUpdatedComment.rawValue, value: newValue) }
    }

    var firstLaunchApp: Bool {
        get { return value(for: UserDefaultManagerKey.firstLaunchApp.rawValue) ?? true }
        set { updateDefaults(for: UserDefaultManagerKey.firstLaunchApp.rawValue, value: newValue) }
    }
    
    var noShowFirstInterAd: Bool {
        get { return value(for: UserDefaultManagerKey.noShowFirstInterAd.rawValue) ?? true }
        set { updateDefaults(for: UserDefaultManagerKey.noShowFirstInterAd.rawValue, value: newValue) }
    }
    
    var firstShowWarningRecord: Bool {
        get { return value(for: UserDefaultManagerKey.firstShowWarningRecord.rawValue) ?? true }
        set { updateDefaults(for: UserDefaultManagerKey.firstShowWarningRecord.rawValue, value: newValue) }
    }

    var numberOfLaunches: Int {
        get { return value(for: UserDefaultManagerKey.numberOfLaunches.rawValue) ?? 0 }
        set { updateDefaults(for: UserDefaultManagerKey.numberOfLaunches.rawValue, value: newValue) }
    }

    var hasSeenGetStarted: Bool {
        get { return value(for: UserDefaultManagerKey.hasSeenGetStarted.rawValue) ?? false }
        set { updateDefaults(for: UserDefaultManagerKey.hasSeenGetStarted.rawValue, value: newValue) }
    }

    /// Playlists marked with the heart on the Playlist screen.
    var favoritePlaylistIDs: [String] {
        get { return value(for: UserDefaultManagerKey.favoritePlaylistIDs.rawValue) ?? [] }
        set { updateDefaults(for: UserDefaultManagerKey.favoritePlaylistIDs.rawValue, value: newValue) }
    }

    var isRated: Bool {
        get {return value(for: UserDefaultManagerKey.isRated.rawValue) ?? false}
        set { updateDefaults(for: UserDefaultManagerKey.isRated.rawValue, value: newValue)}
    }
    
    var timeRecord: Int {
        get {return value(for: UserDefaultManagerKey.timeRecord.rawValue) ?? 0}
        set { updateDefaults(for: UserDefaultManagerKey.timeRecord.rawValue, value: newValue)}
    }
    
    var timeDetect: Int {
        get {return value(for: UserDefaultManagerKey.timeDetect.rawValue) ?? 0}
        set { updateDefaults(for: UserDefaultManagerKey.timeDetect.rawValue, value: newValue)}
    }
    
    var appLanguage: String {
        get { return value(for: UserDefaultManagerKey.appLanguage.rawValue) ?? ""}
        set { updateDefaults(for: UserDefaultManagerKey.appLanguage.rawValue, value: newValue) }
    }
    
    var firstSelectedLanguage: Bool {
        set { updateDefaults(for: UserDefaultManagerKey.firstSelectedLanguage.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.firstSelectedLanguage.rawValue) ?? true }
    }
    
    var isSelectedLanguage: Bool {
        set { updateDefaults(for: UserDefaultManagerKey.isSelectedLanguage.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.isSelectedLanguage.rawValue) ?? false }
    }
    
    var accumulatedAdRevenueAmount: Double {
        set { updateDefaults(for: UserDefaultManagerKey.accumulatedAdRevenueAmount.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.accumulatedAdRevenueAmount.rawValue) ?? 0 }
    }
    
    var petName: String {
        set { updateDefaults(for: UserDefaultManagerKey.petName.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.petName.rawValue) ?? "" }
    }
    
    var petGender: String {
        set { updateDefaults(for: UserDefaultManagerKey.petGender.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.petGender.rawValue) ?? "male" }
    }
    
    var petAge: String {
        set { updateDefaults(for: UserDefaultManagerKey.petAge.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.petAge.rawValue) ?? "" }
    }
    
    
    var petGoals: [String] {
        set { updateDefaults(for: UserDefaultManagerKey.petGoals.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.petGoals.rawValue) ?? [] }
    }
    
    var isShowNativeFull: Bool {
        set { updateDefaults(for: UserDefaultManagerKey.isShowNativeFull.rawValue, value: newValue) }
        get { return value(for: UserDefaultManagerKey.isShowNativeFull.rawValue) ?? false }
    }
    
    var countChatWithAI: Int {
        get { return (value(for: UserDefaultManagerKey.countChatWithAI.rawValue)) ?? 0 }
        set { updateDefaults(for: UserDefaultManagerKey.countChatWithAI.rawValue, value: newValue) }
    }

    var watchLimitWatchedDuration: Double {
        get { return max(value(for: UserDefaultManagerKey.watchLimitWatchedDuration.rawValue) ?? 0, 0) }
        set { updateDefaults(for: UserDefaultManagerKey.watchLimitWatchedDuration.rawValue, value: max(newValue, 0)) }
    }
}

extension UserDefaultManager {

    private func updateDefaults(for key: String, value: Any) {
        userDefaults.set(value, forKey: key)
    }

    private func value<T>(for key: String) -> T? {
        return userDefaults.value(forKey: key) as? T
    }

}
