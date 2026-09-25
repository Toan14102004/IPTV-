import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    private let storeName = "I340_IPTV"

    private(set) lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: storeName, managedObjectModel: Self.managedObjectModel)
        container.persistentStoreDescriptions.first?.url = storeURL
        container.loadPersistentStores { [weak self] _, error in
            guard let error else { return }
            print("❌ CoreData load failed: \(error.localizedDescription)")
            self?.resetStore(in: container)
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    private init() {}

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    private var storeURL: URL {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(storeName).sqlite")
    }

    /// Delete the corrupted store and retry once, like the previous Realm setup did.
    private func resetStore(in container: NSPersistentContainer) {
        let coordinator = container.persistentStoreCoordinator
        if let store = coordinator.persistentStores.first {
            try? coordinator.remove(store)
        }
        try? coordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType)
        container.loadPersistentStores { _, error in
            if let error {
                print("❌ CoreData reload failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Model

extension CoreDataStack {
    static let playlistEntityName = "CDPlaylist"
    static let channelEntityName = "CDChannel"

    /// Built in code so the schema lives next to the managed object classes.
    static let managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let playlist = NSEntityDescription()
        playlist.name = playlistEntityName
        playlist.managedObjectClassName = NSStringFromClass(CDPlaylist.self)
        playlist.properties = [
            attribute("id", .stringAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("url", .stringAttributeType, defaultValue: ""),
            attribute("sourceRaw", .stringAttributeType, defaultValue: IPTVPlaylistSource.unknown.rawValue),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType)
        ]
        playlist.uniquenessConstraints = [["id"]]

        let channel = NSEntityDescription()
        channel.name = channelEntityName
        channel.managedObjectClassName = NSStringFromClass(CDChannel.self)
        let playlistID = attribute("playlistID", .stringAttributeType)
        channel.properties = [
            attribute("id", .stringAttributeType),
            playlistID,
            attribute("orderIndex", .integer64AttributeType, defaultValue: 0),
            attribute("title", .stringAttributeType, defaultValue: ""),
            attribute("duration", .integer64AttributeType, defaultValue: -1),
            attribute("url", .stringAttributeType, defaultValue: ""),
            attribute("imageURL", .stringAttributeType, defaultValue: ""),
            attribute("groupTitle", .stringAttributeType, defaultValue: "")
        ]
        channel.indexes = [
            NSFetchIndexDescription(
                name: "byPlaylistID",
                elements: [NSFetchIndexElementDescription(property: playlistID, collationType: .binary)]
            )
        ]

        model.entities = [playlist, channel]
        return model
    }()

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = type
        description.isOptional = false
        description.defaultValue = defaultValue
        return description
    }
}
