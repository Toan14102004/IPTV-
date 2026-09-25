//
//  NetworkError.swift
//  I340_IPTV
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noConnection
    case timeout
    case unauthorized
    case notFound
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .noConnection: "no_internet_message".localized
        case .timeout: "Request timed out"
        case .unauthorized: "Unauthorized access"
        case .notFound: "Not found"
        case let .serverError(_, message): message
        case let .decodingError(error): "Decoding error: \(Self.decodingDetail(error))"
        case let .encodingError(error): "Encoding error: \(error.localizedDescription)"
        case .noData: "No data received"
        case .cancelled: "Cancelled"
        case let .unknown(error): error.localizedDescription
        }
    }

    /// `DecodingError.localizedDescription` never names the broken field; read the case instead.
    private static func decodingDetail(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else { return error.localizedDescription }

        switch decodingError {
        case let .keyNotFound(key, context):
            return "missing key '\(key.stringValue)' at \(path(context))"
        case let .typeMismatch(type, context):
            return "expected \(type) at \(path(context)) -- \(context.debugDescription)"
        case let .valueNotFound(type, context):
            return "missing value for \(type) at \(path(context))"
        case let .dataCorrupted(context):
            return "corrupted data at \(path(context)) -- \(context.debugDescription)"
        @unknown default:
            return decodingError.localizedDescription
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        context.codingPath.isEmpty ? "<root>" : context.codingPath.map(\.stringValue).joined(separator: ".")
    }
}
