//
//  RemoteConfigPropertyWrapper.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import Foundation

/// Static dictionary to store all default values (auto-registered by property wrappers)
/// This is populated automatically when each @RemoteKonfigProperty is initialized
private var _remoteConfigDefaults: [String: NSObject] = [:]

/// Property wrapper for Remote Config values
/// Usage: @RemoteKonfigProperty(key: "i222_is_show_ad_language", default: true) var isShowAdLanguage: Bool
///
/// IMPORTANT: The property wrapper's init() is called when the property is initialized.
/// When RemoteKonfig.shared is created, all instance properties are initialized automatically,
/// so all defaults are registered without manual listing!
@propertyWrapper
struct RemoteKonfigProperty<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            switch defaultValue {
            case is Bool:
                return RemoteConfigHelper.shared.getBoolValue(
                    key: key,
                    defaultValue: defaultValue as! Bool
                ) as! T
            case is Int:
                return RemoteConfigHelper.shared.getIntValue(
                    key: key,
                    defaultValue: defaultValue as! Int
                ) as! T
            case is Double:
                return RemoteConfigHelper.shared.getDoubleValue(
                    key: key,
                    defaultValue: defaultValue as! Double
                ) as! T
            case is String:
                return RemoteConfigHelper.shared.getStringValue(key: key) as! T
            default:
                fatalError("Unsupported type for RemoteConfig: \(T.self)")
            }
        }
    }
    
    init(key: String, default: T) {
        self.key = key
        self.defaultValue = `default`
        
        // Auto-register default value for Firebase
        // This happens automatically when the property is first accessed
        let nsObject: NSObject
        switch `default` {
        case let boolValue as Bool:
            nsObject = boolValue as NSObject
        case let intValue as Int:
            nsObject = intValue as NSObject
        case let doubleValue as Double:
            nsObject = doubleValue as NSObject
        case let stringValue as String:
            nsObject = stringValue as NSString
        default:
            fatalError("Unsupported default type: \(T.self)")
        }
        
        _remoteConfigDefaults[key] = nsObject
    }
}

/// Get all registered defaults (for Firebase Remote Config initialization)
/// This automatically initializes RemoteKonfig.shared to ensure all property wrappers
/// have registered their defaults - no manual initialization needed!
func getRemoteConfigDefaults() -> [String: NSObject] {
    // Ensure RemoteKonfig.shared is initialized, which triggers all @RemoteKonfigProperty init()
    // This guarantees all defaults are registered before returning the dictionary
    _ = RemoteKonfig.shared
    return _remoteConfigDefaults
}
