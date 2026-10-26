//
//  RoomLog.swift
//  I340_IPTV
//

import Foundation

/// Debug trace of the room traffic, to send to the backend when something fails.
///
/// Debug builds print each line as `[Room] …` in the Xcode console and keep the last lines in
/// memory (`text`); release builds record nothing. Source URLs keep only their host and link
/// tokens are masked: they carry the host's credentials.
enum RoomLog {
    private static let maxLines = 300
    private static let lock = NSLock()
    private static var lines: [String] = []

    /// Everything recorded so far, oldest first.
    static var text: String {
        lock.lock(); defer { lock.unlock() }
        return lines.joined(separator: "\n")
    }

    static func sent(_ event: String, _ body: [String: Any]) {
        record("→ \(event) \(describe(body))")
    }

    static func received(_ event: String, _ payload: Any) {
        record("← \(event) \(describe(payload))")
    }

    static func note(_ message: String) {
        record("• \(message)")
    }

    // MARK: - Private

    private static func record(_ line: String) {
        #if DEBUG
        let stamped = "\(Date().formattedForLog) \(line)"
        lock.lock()
        lines.append(stamped)
        if lines.count > maxLines { lines.removeFirst(lines.count - maxLines) }
        lock.unlock()
        Logger.d(useFullLog: false, "[Room]", line)
        #endif
    }

    private static func describe(_ value: Any) -> String {
        let safe = redact(value)
        guard JSONSerialization.isValidJSONObject(safe),
              let data = try? JSONSerialization.data(withJSONObject: safe, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return "\(safe)" }
        return json
    }

    private static func redact(_ value: Any) -> Any {
        switch value {
        case let dictionary as [String: Any]:
            return dictionary.reduce(into: [String: Any]()) { result, pair in
                switch pair.key {
                case "sourceUrl":
                    let host = (pair.value as? String).flatMap { URL(string: $0)?.host } ?? "?"
                    result[pair.key] = "<\(host)/…>"
                case "hostResumeToken":
                    result[pair.key] = "***"
                case "path":
                    result[pair.key] = (pair.value as? String).map(maskToken) ?? pair.value
                default:
                    result[pair.key] = redact(pair.value)
                }
            }
        case let array as [Any]:
            return array.map(redact)
        default:
            return value
        }
    }

    private static func maskToken(_ path: String) -> String {
        guard let range = path.range(of: "token=") else { return path }
        let rest = path[range.upperBound...]
        let end = rest.firstIndex(of: "&") ?? rest.endIndex
        return path.replacingCharacters(in: range.upperBound..<end, with: "***")
    }
}
