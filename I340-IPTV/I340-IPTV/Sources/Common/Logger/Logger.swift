//
//  Logger.swift
//  I340_IPTV
//

import FirebaseCrashlytics
import Foundation

/// App-wide logging.
///
///     Logger.d("loaded", playlist.name)   // debug
///     Logger.e("import failed", error)    // error: also breadcrumb in Crashlytics
///
/// Debug builds print every level; release builds print nothing (set `isEnabled`), but errors
/// and warnings are always added to the Crashlytics log so a crash report carries them.
struct Logger {
    private init() {}

    #if DEBUG
    static var isEnabled = true
    #else
    static var isEnabled = false
    #endif

    private static let queue = DispatchQueue(label: "com.i340.logger", qos: .utility)

    static func log(
        level: LogLevel,
        useFullLog: Bool = true,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: Int = #line,
        messages: [Any]
    ) {
        let text = messages.map { "\($0)" }.joined(separator: " ")
        let location = "\(file):\(line) \(function)"

        if level == .error || level == .warning {
            Crashlytics.crashlytics().log("[\(level)] \(location) \(text)")
        }

        guard isEnabled else { return }
        queue.async {
            let head = "\(Date().formattedForLog) \(level.symbol)"
            print(useFullLog ? "\(head) \(location) \(text)" : "\(head) \(text)")
        }
    }

    static func d(
        useFullLog: Bool = true, file: StaticString = #fileID, function: StaticString = #function,
        line: Int = #line, _ messages: Any...
    ) {
        log(level: .debug, useFullLog: useFullLog, file: file, function: function, line: line, messages: messages)
    }

    static func w(
        useFullLog: Bool = true, file: StaticString = #fileID, function: StaticString = #function,
        line: Int = #line, _ messages: Any...
    ) {
        log(level: .warning, useFullLog: useFullLog, file: file, function: function, line: line, messages: messages)
    }

    static func n(
        useFullLog: Bool = true, file: StaticString = #fileID, function: StaticString = #function,
        line: Int = #line, _ messages: Any...
    ) {
        log(level: .notice, useFullLog: useFullLog, file: file, function: function, line: line, messages: messages)
    }

    static func e(
        useFullLog: Bool = true, file: StaticString = #fileID, function: StaticString = #function,
        line: Int = #line, _ messages: Any...
    ) {
        log(level: .error, useFullLog: useFullLog, file: file, function: function, line: line, messages: messages)
    }
}
