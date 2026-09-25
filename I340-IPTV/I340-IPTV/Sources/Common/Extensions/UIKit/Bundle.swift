//
//  Bundle.swift
//  I340_IPTV
//
//  Created by Foxcode on 9/9/24.
//

import UIKit

extension Bundle {
    private static var bundle: Bundle!
    
    public static func localizedBundle() -> Bundle! {
        if bundle == nil {
            let appLang = UserDefaultManager.shared().appLanguage
            let path = Bundle.main.path(forResource: appLang, ofType: "lproj")
            bundle = Bundle(path: path!)
        }
        
        return bundle
    }
    
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
    
    public static func setLanguage(lang: String) {
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj") {
            UserDefaultManager.shared().appLanguage = lang
            bundle = Bundle(path: path)
        } else {
            UserDefaultManager.shared().appLanguage = "en"
            let path = Bundle.main.path(forResource: "en", ofType: "lproj")
            bundle = Bundle(path: path!)
        }
    }
    
    var displayName: String {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return name
        }
        return object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
    
    var version: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        } else {
            return ""
        }
    }
}
