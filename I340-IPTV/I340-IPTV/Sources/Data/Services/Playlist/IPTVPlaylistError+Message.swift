//
//  IPTVPlaylistError+Message.swift
//  I340_IPTV
//

import Foundation

extension IPTVPlaylistError {
    /// Text shown to the user for an import / edit failure.
    static func message(for error: Error) -> String {
        guard let playlistError = error as? IPTVPlaylistError else {
            return localized("generic_error_message", fallback: "An error occurred. Please try again.")
        }

        switch playlistError {
        case .emptyName, .emptyURL:
            return localized("playlist_add_name_url_empty_error", fallback: "Please enter playlist name and URL.")
        case .invalidURL, .emptyPlaylist, .fileReadFailed:
            return localized("playlist_add_invalid_or_empty_error", fallback: "Playlist is invalid or empty.")
        case .fileCopyFailed:
            return localized("playlist_add_file_error", fallback: "Please select a valid M3U file.")
        case .invalidPlaylistContent:
            return localized("playlist_add_content_not_found_error", fallback: "Playlist content not found. Please check the URL again.")
        case .playlistRequestTimeout:
            return localized("playlist_add_timeout_error", fallback: "The request timed out. Please try again.")
        case .duplicateURL:
            return localized("playlist_add_duplicate_url_error", fallback: "This playlist URL already exists.")
        case .playlistNotFound, .channelNotFound:
            return localized("generic_error_message", fallback: "An error occurred. Please try again.")
        case .unplayablePlaylist:
            return localized("playlist_add_unplayable_file_error", fallback: "This file cannot be played. Please choose another file.")
        case .duplicateName:
            return localized("playlist_add_duplicate_name_error", fallback: "A playlist with this name already exists. Please choose another name.")
        case .xtreamAccessDenied:
            return localized("playlist_add_xtream_access_denied_error", fallback: "Unable to access this Xtream account. Please check the server URL, username, and password.")
        }
    }

    private static func localized(_ key: String, fallback: String) -> String {
        let value = key.localized
        return value == key || value.isEmpty ? fallback : value
    }
}
