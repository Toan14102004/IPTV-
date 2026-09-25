//
//  Endpoint.swift
//  I340_IPTV
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// One API call. Declare the calls of a feature as an enum:
///
///     enum PlaylistEndpoint: Endpoint {
///         case list
///         var path: String { "/playlists" }
///     }
protocol Endpoint {
    /// Overrides `NetworkService.baseURL` when set.
    var baseURL: String? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var query: [String: String] { get }
    var headers: [String: String] { get }
    var body: Encodable? { get }
}

extension Endpoint {
    var baseURL: String? { nil }
    var method: HTTPMethod { .get }
    var query: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var body: Encodable? { nil }
}

/// Ad-hoc endpoint for one-off calls.
struct RawEndpoint: Endpoint {
    var baseURL: String?
    var path: String
    var method: HTTPMethod = .get
    var query: [String: String] = [:]
    var headers: [String: String] = [:]
    var body: Encodable?
}
