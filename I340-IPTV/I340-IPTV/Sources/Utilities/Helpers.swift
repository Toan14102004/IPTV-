//
//  Helpers.swift
//  I340_IPTV
//

import Foundation
import StoreKit
import UIKit

class Utils {
    static func openAppStore(_ appId: String = Configs.InfoApp.appId) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/\(appId)"),
           UIApplication.shared.canOpenURL(url){
            UIApplication.shared.open(url, options: [:]) { (opened) in
                if(opened){
                    print("App Store Opened")
                }
            }
        } else {
            print("Can't Open URL on Simulator")
        }
    }
    
    static func getCurrenLanguageCode() -> String {
        var languageCode = ""
        if #available(iOS 16.0, *) {
            if let language = NSLocale.current.language.languageCode {
                languageCode = language.identifier
            }
        } else {
            if let language = NSLocale.current.languageCode {
                languageCode = language
            }
        }
        
        return languageCode
    }
    
}

// MARK: - Rate for app

func showRateForApp() {
    if #available(iOS 10.3, *) {
        SKStoreReviewController.requestReview()
    } else if let url = URL(string: "itms-apps://itunes.apple.com/app/" + Configs.InfoApp.appId) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

func navigateToRateScreen() {
    UserDefaultManager.shared().isRated = true
    let appId = Configs.InfoApp.appId
    let url = URL(string: "itms-apps:itunes.apple.com/us/app/apple-store/id\(appId)?mt=8&action=write-review")!
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}

func openURL(_ url: URL, onCompleted: (() -> Void)? = nil) {
    if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
