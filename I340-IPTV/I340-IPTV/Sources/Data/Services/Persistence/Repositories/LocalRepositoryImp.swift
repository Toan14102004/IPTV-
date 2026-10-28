import Foundation

final class LocalRepositoryImp: LocalRepository {
    static let shared = LocalRepositoryImp()

    private let playlistDAO: IPTVPlaylistDAO

    init(playlistDAO: IPTVPlaylistDAO = IPTVPlaylistDAO()) {
        self.playlistDAO = playlistDAO
    }

    func getAllPlaylists() async throws -> [IPTVPlaylist] {
        playlistDAO.findPlaylists(includeChannels: true)
    }

    func getPlaylistSummaries() async throws -> [IPTVPlaylist] {
        playlistDAO.findPlaylists(includeChannels: false)
    }

    func getPlaylist(id: String) async throws -> IPTVPlaylist? {
        playlistDAO.findPlaylist(id: id)
    }

    func playlistExists(url: String) async throws -> Bool {
        playlistDAO.playlistExists(url: url.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func savePlaylist(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist {
        var item = playlist
        let now = Date()
        if item.id.isEmpty {
            item.id = UUID().uuidString
        }
        if item.createdAt.timeIntervalSince1970 <= 0 {
            item.createdAt = now
        }
        item.updatedAt = now
        return playlistDAO.save(item)
    }

    func updatePlaylist(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist {
        var item = playlist
        item.updatedAt = Date()
        return playlistDAO.save(item)
    }

    func savePlaylistQuietly(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist {
        playlistDAO.save(playlist)
    }

    func deletePlaylist(id: String) async throws {
        playlistDAO.deletePlaylist(id: id)
    }
}
