import Foundation

protocol M3UPlaylistParsing {
    func parse(m3uContent: String?) -> [IPTVChannel]
    func parse(m3uContent: String?, baseURL: URL?) -> [IPTVChannel]
    func parseFile(url: URL) -> [IPTVChannel]?
}

final class M3UPlaylistParser: M3UPlaylistParsing {
    static let shared = M3UPlaylistParser()
    
    private init() {}
    
    func parse(m3uContent: String?) -> [IPTVChannel] {
        parse(m3uContent: m3uContent, baseURL: nil)
    }
    
    func parse(m3uContent: String?, baseURL: URL?) -> [IPTVChannel] {
        guard let m3uContent, !isHTMLContent(m3uContent) else { return [] }
        
        let lines = m3uContent.components(separatedBy: .newlines)
        var channels: [IPTVChannel] = []
        var currentChannel: IPTVChannel?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            if trimmedLine.uppercased().hasPrefix("#EXTINF") {
                var channel = IPTVChannel()
                channel.duration = extractDuration(from: trimmedLine)
                channel.title = extractTitle(from: trimmedLine)
                channel.imageURL = firstAttribute(["tvg-logo", "logo"], from: trimmedLine)
                channel.groupTitle = firstAttribute(["group-title", "group"], from: trimmedLine)
                currentChannel = channel
            } else if trimmedLine.uppercased().hasPrefix("#EXTGRP:") {
                currentChannel?.groupTitle = String(trimmedLine.dropFirst("#EXTGRP:".count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("#") {
                continue
            } else if let streamURL = resolvedStreamURL(from: trimmedLine, baseURL: baseURL) {
                var channel = currentChannel ?? IPTVChannel()
                channel.id = UUID().uuidString
                channel.url = streamURL
                if channel.title.isEmpty {
                    channel.title = fallbackTitle(from: streamURL, index: channels.count + 1)
                }
                channels.append(channel)
                currentChannel = nil
            }
        }
        
        return channels
    }
    
    func parseFile(url: URL) -> [IPTVChannel]? {
        do {
            let data = try Data(contentsOf: url)
            guard let m3uContent = decodePlaylistData(data) else { return nil }
            return parse(m3uContent: m3uContent, baseURL: nil)
        } catch {
            print("M3U parse file error: \(error.localizedDescription). URL: \(url)")
            return nil
        }
    }
    
    private func extractDuration(from line: String) -> Int {
        guard let durationRange = line.range(of: "#EXTINF:") else { return -1 }
        let afterPrefix = line[durationRange.upperBound...]
        guard let commaIndex = afterPrefix.firstIndex(of: ",") else { return -1 }
        return Int(afterPrefix[..<commaIndex].trimmingCharacters(in: .whitespaces)) ?? -1
    }
    
    private func extractTitle(from line: String) -> String {
        if let commaIndex = firstCommaOutsideQuotes(in: line) {
            let title = line[line.index(after: commaIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { return title }
        }
        
        return firstAttribute(["tvg-name", "name", "channel-name", "title", "tvg-id"], from: line)
    }
    
    private func extractAttribute(_ name: String, from line: String) -> String {
        let pattern = #"(?:^|\s)\#(name)=("[^"]*"|'[^']*'|[^\s,]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return ""
        }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              match.numberOfRanges >= 2,
              let valueRange = Range(match.range(at: 1), in: line) else { return "" }
        
        let value = String(line[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }
    
    private func firstAttribute(_ names: [String], from line: String) -> String {
        for name in names {
            let value = extractAttribute(name, from: line)
            if !value.isEmpty { return value }
        }
        return ""
    }
    
    private func firstCommaOutsideQuotes(in line: String) -> String.Index? {
        var activeQuote: Character?
        var index = line.startIndex
        
        while index < line.endIndex {
            let character = line[index]
            if character == "\"" || character == "'" {
                if activeQuote == character {
                    activeQuote = nil
                } else if activeQuote == nil {
                    activeQuote = character
                }
            } else if character == ",", activeQuote == nil {
                return index
            }
            
            index = line.index(after: index)
        }
        
        return nil
    }
    
    private func resolvedStreamURL(from line: String, baseURL: URL?) -> String? {
        let value = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'")))
        guard !value.isEmpty else { return nil }
        guard !isMarkupLine(value), !hasInvalidStreamURLCharacters(value) else { return nil }
        
        if value.hasPrefix("//") {
            return "https:\(value)"
        }
        
        if let url = URL(string: value),
           let scheme = url.scheme?.lowercased(),
           isSupportedStreamScheme(scheme) {
            return url.absoluteString
        }
        
        guard let baseURL,
              let baseScheme = baseURL.scheme?.lowercased(),
              ["http", "https"].contains(baseScheme),
              let url = URL(string: value, relativeTo: baseURL)?.absoluteURL,
              let scheme = url.scheme?.lowercased(),
              isSupportedStreamScheme(scheme) else {
            return nil
        }
        
        return url.absoluteString
    }
    
    private func isSupportedStreamScheme(_ scheme: String) -> Bool {
        ["http", "https", "rtmp", "rtsp", "udp", "rtp", "mms", "ftp", "file"].contains(scheme)
    }
    
    private func isHTMLContent(_ content: String) -> Bool {
        let prefix = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(512)
            .lowercased()
        
        return prefix.hasPrefix("<!doctype")
        || prefix.hasPrefix("<html")
        || prefix.hasPrefix("<head")
        || prefix.hasPrefix("<body")
        || prefix.contains("<!doctype html")
        || prefix.contains("<html")
        || prefix.contains("<head")
        || prefix.contains("<body")
    }
    
    private func isMarkupLine(_ value: String) -> Bool {
        let lowercasedValue = value.lowercased()
        return lowercasedValue.hasPrefix("<!doctype")
        || lowercasedValue.hasPrefix("<html")
        || lowercasedValue.hasPrefix("<head")
        || lowercasedValue.hasPrefix("<body")
        || lowercasedValue.hasPrefix("<script")
        || lowercasedValue.hasPrefix("<meta")
        || lowercasedValue.hasPrefix("<link")
        || lowercasedValue.hasPrefix("</")
        || (lowercasedValue.hasPrefix("<") && lowercasedValue.hasSuffix(">"))
    }
    
    private func hasInvalidStreamURLCharacters(_ value: String) -> Bool {
        value.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        || value.rangeOfCharacter(from: CharacterSet(charactersIn: "<>\"'")) != nil
    }
    
    private func fallbackTitle(from streamURL: String, index: Int) -> String {
        guard let url = URL(string: streamURL) else {
            return "Channel \(index)"
        }
        
        let lastPathComponent = url.deletingPathExtension().lastPathComponent.removingPercentEncoding ?? ""
        let trimmedTitle = lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "Channel \(index)" : trimmedTitle
    }
    
    private func decodePlaylistData(_ data: Data) -> String? {
        for encoding in [String.Encoding.utf8, .windowsCP1252, .isoLatin1, .ascii] {
            if let content = String(data: data, encoding: encoding) {
                return content
            }
        }
        return nil
    }
}
