//
//  AppError.swift
//  I340_IPTV
//

import Foundation

/// One shape for every failure the UI shows: a message for the user and whether trying again can help.
///
///     catch { toast = AppError(error).message }
struct AppError: LocalizedError, Equatable {
    let message: String
    let isRetryable: Bool

    var errorDescription: String? { message }

    init(message: String, isRetryable: Bool = false) {
        self.message = message
        self.isRetryable = isRetryable
    }

    init(_ error: Error) {
        if let appError = error as? AppError {
            self = appError
            return
        }

        switch error {
        case let networkError as NetworkError:
            switch networkError {
            case .noConnection, .timeout:
                self.init(message: "no_internet_message".localized, isRetryable: true)
            default:
                self.init(message: "generic_error_message".localized, isRetryable: true)
            }
        case is IPTVPlaylistError:
            self.init(message: IPTVPlaylistError.message(for: error), isRetryable: false)
        case let urlError as URLError where urlError.code == .notConnectedToInternet:
            self.init(message: "no_internet_message".localized, isRetryable: true)
        default:
            self.init(message: "generic_error_message".localized, isRetryable: true)
        }
    }
}
