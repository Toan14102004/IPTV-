//
//  StreamRequestBuilder.swift
//  I340_IPTV
//

import AVFoundation
import Foundation

/// Builds the `AVURLAsset` used to play IPTV streams: some providers only serve HLS for `.ts`
/// links, expect a player-like User-Agent and take Xtream credentials from the URL path.
enum StreamRequestBuilder {
    static func asset(for url: URL) -> AVURLAsset {
        let playbackURL = preferredPlaybackURL(from: url)
        return AVURLAsset(
            url: playbackURL,
            options: ["AVURLAssetHTTPHeaderFieldsKey": headers(for: playbackURL)]
        )
    }

    static func preferredPlaybackURL(from url: URL) -> URL {
        guard url.pathExtension.lowercased() == "ts",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.path = (components.path as NSString).deletingPathExtension + ".m3u8"
        return components.url ?? url
    }

    static func headers(for url: URL) -> [String: String] {
        var headers = [
            "User-Agent": "VLC/3.0.18 LibVLC/3.0.18",
            "Accept": "*/*",
            "Icy-MetaData": "1"
        ]
        if let authorization = basicAuthorizationHeader(from: url) {
            headers["Authorization"] = authorization
        }
        return headers
    }

    /// Xtream URLs look like `/live/<username>/<password>/<id>.ts`.
    private static func basicAuthorizationHeader(from url: URL) -> String? {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard
            let typeIndex = pathComponents.firstIndex(where: { ["live", "movie", "series"].contains($0.lowercased()) }),
            pathComponents.indices.contains(typeIndex + 2)
        else {
            return nil
        }
        let username = pathComponents[typeIndex + 1]
        let password = pathComponents[typeIndex + 2]
        guard !username.isEmpty, !password.isEmpty else { return nil }
        guard let data = "\(username):\(password)".data(using: .utf8) else { return nil }
        return "Basic \(data.base64EncodedString())"
    }
}
