//
//  NetworkService.swift
//  I340_IPTV
//

import Foundation

/// The app's HTTP client (`URLSession`, async/await). Cancelling the calling `Task` cancels the request.
///
///     @Injected var network: NetworkService
///     let items: [Item] = try await network.request(MyEndpoint.list)
final class NetworkService {
    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    /// How many times a request that failed for a transient reason (timeout, no connection) is tried again.
    private let retryCount: Int

    init(
        baseURL: String = Configs.Network.Base_URL,
        session: URLSession = NetworkService.makeSession(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        retryCount: Int = 1
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.retryCount = retryCount
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Configs.Network.networkTimeout
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    // MARK: - Requests

    /// Decoded response of `endpoint`.
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let data = try await send(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.e("Decoding failed for \(endpoint.path)", error)
            throw NetworkError.decodingError(error)
        }
    }

    /// Raw response body of `endpoint`.
    @discardableResult
    func send(_ endpoint: Endpoint) async throws -> Data {
        let request = try makeRequest(for: endpoint)
        var attempt = 0

        while true {
            do {
                return try await perform(request)
            } catch let error as NetworkError where attempt < retryCount && error.isTransient {
                attempt += 1
                Logger.w("Retrying (\(attempt)/\(retryCount)) \(request.url?.absoluteString ?? "")", error)
                try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
            }
        }
    }

    // MARK: - Private

    private func perform(_ request: URLRequest) async throws -> Data {
        Logger.d("→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else { throw NetworkError.noData }
        Logger.d("← \(http.statusCode) \(request.url?.absoluteString ?? "")")

        switch http.statusCode {
        case 200 ..< 300: return data
        case 401, 403: throw NetworkError.unauthorized
        case 404: throw NetworkError.notFound
        default:
            let message = String(data: data, encoding: .utf8).flatMap { $0.isEmpty ? nil : $0 }
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw NetworkError.serverError(statusCode: http.statusCode, message: message)
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: (endpoint.baseURL ?? baseURL) + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingError(error)
            }
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        return request
    }

    private static func map(_ error: URLError) -> NetworkError {
        switch error.code {
        case .timedOut: .timeout
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: .noConnection
        case .cancelled: .cancelled
        default: .unknown(error)
        }
    }
}

private extension NetworkError {
    /// Worth trying again.
    var isTransient: Bool {
        switch self {
        case .timeout, .noConnection: true
        default: false
        }
    }
}

/// Lets an `Encodable` existential go through `JSONEncoder`.
private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
