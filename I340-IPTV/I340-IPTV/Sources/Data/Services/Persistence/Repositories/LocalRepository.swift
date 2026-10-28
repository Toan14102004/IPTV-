import Foundation

/// Persistence of the imported playlists (Core Data).
protocol LocalRepository {
    func getAllPlaylists() async throws -> [IPTVPlaylist]
    /// Playlists without their channels (cheap; for lists).
    func getPlaylistSummaries() async throws -> [IPTVPlaylist]
    func getPlaylist(id: String) async throws -> IPTVPlaylist?
    func playlistExists(url: String) async throws -> Bool
    func savePlaylist(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist
    func updatePlaylist(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist
    /// Saves without touching `updatedAt`, for corrections the user did not ask for — the lists are
    /// ordered by that date, so bumping it would reshuffle them behind the user's back.
    func savePlaylistQuietly(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist
    func deletePlaylist(id: String) async throws
}
