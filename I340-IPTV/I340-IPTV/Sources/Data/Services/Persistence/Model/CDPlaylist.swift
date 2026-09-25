import CoreData
import Foundation

@objc(CDPlaylist)
final class CDPlaylist: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var url: String
    @NSManaged var sourceRaw: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date

    func asModel(channels: [IPTVChannel] = []) -> IPTVPlaylist {
        IPTVPlaylist(
            id: id,
            name: name,
            url: url,
            source: IPTVPlaylistSource(rawValue: sourceRaw) ?? .unknown,
            channels: channels,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(_ playlist: IPTVPlaylist) {
        id = playlist.id
        name = playlist.name
        url = playlist.url
        sourceRaw = playlist.source.rawValue
        createdAt = playlist.createdAt
        updatedAt = playlist.updatedAt
    }
}
