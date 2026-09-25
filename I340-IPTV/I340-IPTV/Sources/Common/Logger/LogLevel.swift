//
//  LogLevel.swift
//  I340_IPTV
//

import Foundation

enum LogLevel {
    case debug
    case warning
    case notice
    case error

    var symbol: String {
        switch self {
        case .debug: "DEBUG ✅"
        case .warning: "WARNING ⚠️"
        case .notice: "NOTICE 📣"
        case .error: "ERROR ❌"
        }
    }
}
