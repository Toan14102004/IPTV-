//
//  CacheService.swift
//  I340_IPTV
//

import Foundation
import Kingfisher

/// Everything the app can rebuild: downloaded images, URL responses, temporary files and the
/// small data cache below. It never touches user data (Core Data, UserDefaults, Keychain).
///
///     @Injected var cache: CacheService
///     let size = await cache.totalSize()      // bytes
///     await cache.clearAll()
///
///     // Small values that expire (API responses, parsed feeds, …)
///     try cache.store(items, forKey: "featured", ttl: 3600)
///     let items: [Item]? = cache.value([Item].self, forKey: "featured")
final class CacheService {
    private let fileManager: FileManager
    private let dataDirectory: URL
    private let imageCache: ImageCache
    private let urlCache: URLCache

    init(
        fileManager: FileManager = .default,
        imageCache: ImageCache = .default,
        urlCache: URLCache = .shared
    ) {
        self.fileManager = fileManager
        self.imageCache = imageCache
        self.urlCache = urlCache

        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        dataDirectory = base.appendingPathComponent("DataCache", isDirectory: true)
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Images

    /// Downloads happen through Kingfisher (`RemoteImageView`); these limits keep it bounded.
    func configureImageCache(memoryLimitMB: Int = 100, diskLimitMB: Int = 300, expiration: TimeInterval = 7 * 86_400) {
        imageCache.memoryStorage.config.totalCostLimit = memoryLimitMB * 1024 * 1024
        imageCache.diskStorage.config.sizeLimit = UInt(diskLimitMB * 1024 * 1024)
        imageCache.diskStorage.config.expiration = .seconds(expiration)
    }

    // MARK: - Data cache

    private struct Entry<Value: Codable>: Codable {
        let expiresAt: Date?
        let value: Value
    }

    /// Saves `value` under `key`; `ttl` nil keeps it until the cache is cleared.
    func store<Value: Codable>(_ value: Value, forKey key: String, ttl: TimeInterval? = nil) throws {
        let entry = Entry(expiresAt: ttl.map { Date().addingTimeInterval($0) }, value: value)
        try JSONEncoder().encode(entry).write(to: url(for: key), options: .atomic)
    }

    /// The stored value, or nil when missing, expired or unreadable.
    func value<Value: Codable>(_ type: Value.Type, forKey key: String) -> Value? {
        let fileURL = url(for: key)
        guard let data = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(Entry<Value>.self, from: data) else { return nil }

        if let expiresAt = entry.expiresAt, expiresAt < Date() {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        return entry.value
    }

    func removeValue(forKey key: String) {
        try? fileManager.removeItem(at: url(for: key))
    }

    // MARK: - Size & clear

    /// Bytes used by images, URL responses and the data cache.
    func totalSize() async -> Int64 {
        let images = await withCheckedContinuation { (continuation: CheckedContinuation<Int64, Never>) in
            imageCache.calculateDiskStorageSize { result in
                continuation.resume(returning: Int64((try? result.get()) ?? 0))
            }
        }
        return images + Int64(urlCache.currentDiskUsage) + directorySize(dataDirectory)
    }

    /// Removes every cache (images, URL responses, data cache, temporary files).
    func clearAll() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            imageCache.clearMemoryCache()
            imageCache.clearDiskCache { continuation.resume() }
        }
        urlCache.removeAllCachedResponses()
        try? fileManager.removeItem(at: dataDirectory)
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        clearTemporaryDirectory()
        Logger.n("Cache cleared")
    }

    static func formatted(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    // MARK: - Private

    private func url(for key: String) -> URL {
        let safeName = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return dataDirectory.appendingPathComponent(safeName).appendingPathExtension("json")
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let files = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.compactMap { ($0 as? URL)?.fileSize }.reduce(0, +)
    }

    private func clearTemporaryDirectory() {
        let temporary = fileManager.temporaryDirectory
        let contents = (try? fileManager.contentsOfDirectory(at: temporary, includingPropertiesForKeys: nil)) ?? []
        contents.forEach { try? fileManager.removeItem(at: $0) }
    }
}

private extension URL {
    var fileSize: Int64 {
        Int64((try? resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
    }
}
