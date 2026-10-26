//
//  XtreamStreamResolver.swift
//  I340_IPTV
//

import Foundation

/// Series are listed with a `get_series_info` link; this turns it into the URL of the first
/// playable episode.
enum XtreamStreamResolver {
    enum ResolveError: Error {
        case network(Error)
        case badResponse
        case noEpisode
        case parse
    }

    static func isValidStreamURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return nil }
        return url
    }

    static func isSeriesInfoURL(_ url: URL) -> Bool {
        url.absoluteString.contains("action=get_series_info")
    }

    static func firstEpisodeURL(from seriesInfoURL: URL) async throws -> URL {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: seriesInfoURL)
        } catch {
            throw ResolveError.network(error)
        }

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ResolveError.badResponse
        }

        let info: SeriesInfoResponse
        do {
            info = try JSONDecoder().decode(SeriesInfoResponse.self, from: data)
        } catch {
            throw ResolveError.parse
        }

        guard let episode = info.firstPlayableEpisode,
              let url = episodeURL(from: seriesInfoURL, episode: episode) else {
            throw ResolveError.noEpisode
        }
        return url
    }

    static func message(for error: Error) -> String {
        switch error {
        case let ResolveError.network(underlying):
            return String(format: "xtream_load_series_info_error_format".localized, underlying.localizedDescription)
        case ResolveError.badResponse:
            return "xtream_load_series_info_error".localized
        case ResolveError.noEpisode:
            return "xtream_no_playable_episode".localized
        default:
            return "xtream_parse_series_info_error".localized
        }
    }

    private static func episodeURL(from seriesInfoURL: URL, episode: Episode) -> URL? {
        guard var components = URLComponents(url: seriesInfoURL, resolvingAgainstBaseURL: false) else { return nil }
        let queryItems = components.queryItems ?? []
        guard
            let username = queryItems.first(where: { $0.name == "username" })?.value,
            let password = queryItems.first(where: { $0.name == "password" })?.value
        else {
            return nil
        }

        let basePath = components.path
            .replacingOccurrences(of: "player_api.php", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let extensionName = episode.containerExtension?.isEmpty == false ? episode.containerExtension! : "mp4"
        let streamPath = [basePath, "series", username, password, "\(episode.id).\(extensionName)"]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.path = "/\(streamPath)"
        components.queryItems = nil
        return components.url
    }
}

// MARK: - Response

private struct SeriesInfoResponse: Decodable {
    let episodes: [String: [Episode]]

    var firstPlayableEpisode: Episode? {
        episodes
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .flatMap { $0.value }
            .first { !$0.id.isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case episodes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let bySeason = try? container.decode([String: [Episode]].self, forKey: .episodes) {
            episodes = bySeason
        } else if let list = try? container.decode([Episode].self, forKey: .episodes) {
            episodes = ["1": list]
        } else {
            episodes = [:]
        }
    }
}

private struct Episode: Decodable {
    let id: String
    let title: String?
    let containerExtension: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case containerExtension = "container_extension"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lossyString(forKey: .id) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title)
        containerExtension = container.lossyString(forKey: .containerExtension)
    }
}

private extension KeyedDecodingContainer {
    func lossyString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return "\(value)"
        }
        return nil
    }
}
