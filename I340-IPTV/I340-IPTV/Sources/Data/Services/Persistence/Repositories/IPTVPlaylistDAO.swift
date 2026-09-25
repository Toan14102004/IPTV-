import CoreData
import Foundation

final class IPTVPlaylistDAO {
    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    func findPlaylists(includeChannels: Bool) -> [IPTVPlaylist] {
        perform { context in
            let request = NSFetchRequest<CDPlaylist>(entityName: CoreDataStack.playlistEntityName)
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            let playlists = try context.fetch(request)
            return try playlists.map { playlist in
                let channels = includeChannels ? try self.channels(of: playlist.id, in: context) : []
                return playlist.asModel(channels: channels)
            }
        } ?? []
    }

    func findPlaylist(id: String) -> IPTVPlaylist? {
        perform { context in
            guard let playlist = try self.fetchPlaylist(id: id, in: context) else { return nil }
            return playlist.asModel(channels: try self.channels(of: id, in: context))
        } ?? nil
    }

    func playlistExists(url: String) -> Bool {
        perform { context in
            let request = NSFetchRequest<CDPlaylist>(entityName: CoreDataStack.playlistEntityName)
            request.predicate = NSPredicate(format: "url == %@", url)
            request.fetchLimit = 1
            return try context.count(for: request) > 0
        } ?? false
    }

    /// Insert or replace a playlist together with all of its channels.
    @discardableResult
    func save(_ playlist: IPTVPlaylist) -> IPTVPlaylist {
        var item = playlist
        if item.id.isEmpty {
            item.id = UUID().uuidString
        }

        let saved: Void? = perform { context in
            let entity = try self.fetchPlaylist(id: item.id, in: context)
                ?? CDPlaylist(entity: self.playlistEntity(in: context), insertInto: context)
            entity.apply(item)
            try context.save()

            try self.deleteChannels(of: item.id, in: context)
            let rows = item.channels.enumerated().map { index, channel in
                CDChannel.batchRow(for: channel, playlistID: item.id, orderIndex: index)
            }
            if !rows.isEmpty {
                let insert = NSBatchInsertRequest(entityName: CoreDataStack.channelEntityName, objects: rows)
                insert.resultType = .statusOnly
                try context.execute(insert)
            }
        }
        if saved == nil {
            print("❌ CoreData save playlist failed: \(item.id)")
        }
        return item
    }

    @discardableResult
    func deletePlaylist(id: String) -> Bool {
        perform { context in
            guard let playlist = try self.fetchPlaylist(id: id, in: context) else { return false }
            try self.deleteChannels(of: id, in: context)
            context.delete(playlist)
            try context.save()
            return true
        } ?? false
    }

    // MARK: - Private

    /// Runs `work` synchronously on a fresh background context. Returns nil if it throws.
    private func perform<T>(_ work: @escaping (NSManagedObjectContext) throws -> T) -> T? {
        let context = stack.newBackgroundContext()
        var result: T?
        context.performAndWait {
            do {
                result = try work(context)
            } catch {
                print("❌ CoreData error: \(error)")
            }
        }
        return result
    }

    private func playlistEntity(in context: NSManagedObjectContext) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: CoreDataStack.playlistEntityName, in: context)!
    }

    private func fetchPlaylist(id: String, in context: NSManagedObjectContext) throws -> CDPlaylist? {
        let request = NSFetchRequest<CDPlaylist>(entityName: CoreDataStack.playlistEntityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func channels(of playlistID: String, in context: NSManagedObjectContext) throws -> [IPTVChannel] {
        let request = NSFetchRequest<CDChannel>(entityName: CoreDataStack.channelEntityName)
        request.predicate = NSPredicate(format: "playlistID == %@", playlistID)
        request.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
        return try context.fetch(request).map { $0.asModel() }
    }

    private func deleteChannels(of playlistID: String, in context: NSManagedObjectContext) throws {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataStack.channelEntityName)
        fetch.predicate = NSPredicate(format: "playlistID == %@", playlistID)
        let delete = NSBatchDeleteRequest(fetchRequest: fetch)
        delete.resultType = .resultTypeStatusOnly
        try context.execute(delete)
    }
}
