//
//  LoggerDate.swift
//  I340_IPTV
//

import Foundation

extension Date {
    private static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    /// `2026-09-25 13:48:24`, used in log lines.
    var formattedForLog: String { Date.logFormatter.string(from: self) }
}
