import CoreData
import Foundation

@objc(CDChannel)
final class CDChannel: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var playlistID: String
    @NSManaged var orderIndex: Int64
    @NSManaged var title: String
    @NSManaged var duration: Int64
    @NSManaged var url: String
    @NSManaged var imageURL: String
    @NSManaged var groupTitle: String

    func asModel() -> IPTVChannel {
        IPTVChannel(
            id: id,
            title: title,
            duration: Int(duration),
            url: url,
            imageURL: imageURL,
            groupTitle: groupTitle
        )
    }

    /// Dictionary form used by `NSBatchInsertRequest`, which is much faster than
    /// creating managed objects one by one for large playlists.
    static func batchRow(for channel: IPTVChannel, playlistID: String, orderIndex: Int) -> [String: Any] {
        [
            "id": channel.id.isEmpty ? UUID().uuidString : channel.id,
            "playlistID": playlistID,
            "orderIndex": Int64(orderIndex),
            "title": channel.title,
            "duration": Int64(channel.duration),
            "url": channel.url,
            "imageURL": channel.imageURL,
            "groupTitle": channel.groupTitle
        ]
    }
}
