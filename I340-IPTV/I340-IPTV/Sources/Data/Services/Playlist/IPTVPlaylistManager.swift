import Foundation
import AVFoundation
import Darwin

enum IPTVPlaylistError: Error {
    case emptyName
    case emptyURL
    case invalidURL
    case duplicateURL
    case duplicateName
    case emptyPlaylist
    case invalidPlaylistContent
    case playlistRequestTimeout
    case fileReadFailed
    case fileCopyFailed
    case playlistNotFound
    case channelNotFound
    case unplayablePlaylist
    case xtreamAccessDenied
    case multipleVideos
}

/// Imports, stores and edits the playlists (M3U links, files, single streams, Xtream profiles).
/// Every operation is `async throws`: cancelling the calling `Task` cancels the download.
final class IPTVPlaylistManager {
    static let shared = IPTVPlaylistManager()

    private let repository: LocalRepository
    private let parser: M3UPlaylistParsing
    private let fileManager: FileManager

    init(
        repository: LocalRepository = LocalRepositoryImp.shared,
        parser: M3UPlaylistParsing = M3UPlaylistParser.shared,
        fileManager: FileManager = .default
    ) {
        self.repository = repository
        self.parser = parser
        self.fileManager = fileManager
    }

    // MARK: - Read

    func getPlaylists() async throws -> [IPTVPlaylist] {
        try await repository.getAllPlaylists()
    }

    func getPlaylistSummaries() async throws -> [IPTVPlaylist] {
        try await repository.getPlaylistSummaries()
    }

    func getPlaylist(id: String) async throws -> IPTVPlaylist? {
        try await repository.getPlaylist(id: id)
    }

    // MARK: - Write

    func savePlaylist(
        name: String,
        url: String,
        source: IPTVPlaylistSource,
        channels: [IPTVChannel]
    ) async throws -> IPTVPlaylist {
        let playlistName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlistURL = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !playlistName.isEmpty else { throw IPTVPlaylistError.emptyName }
        guard !playlistURL.isEmpty else { throw IPTVPlaylistError.emptyURL }

        let now = Date()
        let playlist = IPTVPlaylist(
            name: playlistName,
            url: playlistURL,
            source: source,
            channels: channels,
            createdAt: now,
            updatedAt: now
        )
        return try await repository.savePlaylist(playlist)
    }

    func updatePlaylist(_ playlist: IPTVPlaylist) async throws -> IPTVPlaylist {
        var item = playlist
        item.updatedAt = Date()
        return try await repository.updatePlaylist(item)
    }

    func updatePlaylistName(id: String, name: String) async throws -> IPTVPlaylist {
        let playlistName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !playlistName.isEmpty else { throw IPTVPlaylistError.emptyName }

        guard var playlist = try await repository.getPlaylist(id: id) else {
            throw IPTVPlaylistError.playlistNotFound
        }
        playlist.name = playlistName
        playlist.updatedAt = Date()
        return try await repository.updatePlaylist(playlist)
    }

    func deletePlaylist(id: String) async throws {
        // Drop the Keychain password too, otherwise it outlives the playlist that referenced it.
        if let playlist = try? await repository.getPlaylist(id: id), playlist.source == .xtream {
            let reference = XtreamProfilePayload.decode(from: playlist.url).passwordReference
            XtreamCredentialStore.delete(reference: reference)
        }
        try await repository.deletePlaylist(id: id)
    }

    /// Renames one channel of `playlist`; returns the stored playlist.
    func renameChannel(in playlist: IPTVPlaylist, channel: IPTVChannel, to name: String) async throws -> IPTVPlaylist {
        let channelName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !channelName.isEmpty else { throw IPTVPlaylistError.emptyName }
        guard let index = playlist.channels.firstIndex(where: { $0.id == channel.id }) else {
            throw IPTVPlaylistError.channelNotFound
        }

        var updated = playlist
        updated.channels[index].title = channelName
        return try await updatePlaylist(updated)
    }

    /// Removes one channel from `playlist`; returns the stored playlist.
    func deleteChannel(from playlist: IPTVPlaylist, channel: IPTVChannel) async throws -> IPTVPlaylist {
        guard let index = playlist.channels.firstIndex(where: { $0.id == channel.id }) else {
            throw IPTVPlaylistError.channelNotFound
        }

        var updated = playlist
        updated.channels.remove(at: index)
        return try await updatePlaylist(updated)
    }

    // MARK: - Import

    func saveXtreamProfile(
        name: String,
        serverURL: String,
        username: String,
        password: String,
        avatarName: String = "avatar_xtream_2"
    ) async throws -> IPTVPlaylist {
        let profileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let server = normalizedXtreamServerURL(serverURL)
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !profileName.isEmpty else { throw IPTVPlaylistError.emptyName }
        guard !server.isEmpty else { throw IPTVPlaylistError.emptyURL }
        guard !user.isEmpty else { throw IPTVPlaylistError.emptyURL }
        guard !pass.isEmpty else { throw IPTVPlaylistError.emptyURL }
        guard isValidRemoteURL(server) else { throw IPTVPlaylistError.invalidURL }

        let encodedURL = XtreamProfilePayload.encode(
            serverURL: server,
            username: user,
            password: pass,
            avatarName: avatarName
        )

        let xtreamPlaylists = try await repository.getAllPlaylists().filter { $0.source == .xtream }
        let hasDuplicateName = xtreamPlaylists.contains {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(profileName) == .orderedSame
        }
        guard !hasDuplicateName else { throw IPTVPlaylistError.duplicateName }

        let hasDuplicateCredential = xtreamPlaylists.contains { playlist in
            let payload = XtreamProfilePayload.decode(from: playlist.url)
            return payload.serverURL.caseInsensitiveCompare(server) == .orderedSame
                && payload.username == user
        }
        guard !hasDuplicateCredential else { throw IPTVPlaylistError.duplicateURL }

        let channels = try await loadXtreamChannels(serverURL: server, username: user, password: pass)
        let now = Date()
        let playlist = IPTVPlaylist(
            name: profileName,
            url: encodedURL,
            source: .xtream,
            channels: channels,
            createdAt: now,
            updatedAt: now
        )
        return try await repository.savePlaylist(playlist)
    }

    func importRemotePlaylist(name: String, url: String) async throws -> IPTVPlaylist {
        let playlistName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlistURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !playlistName.isEmpty, !playlistURL.isEmpty else { throw IPTVPlaylistError.emptyName }
        guard isValidRemoteURL(playlistURL) else { throw IPTVPlaylistError.invalidURL }

        guard try await !repository.playlistExists(url: playlistURL) else { throw IPTVPlaylistError.duplicateURL }

        let channels = try await downloadChannels(from: playlistURL, defaultChannelName: playlistName)
        return try await savePlaylist(name: playlistName, url: playlistURL, source: .playlistURL, channels: channels)
    }

    /// Copies a picked file next to the app's documents and imports it.
    func importLocalFile(fileURL: URL, name: String?) async throws -> IPTVPlaylist {
        guard ["m3u", "m3u8", "w3u"].contains(fileURL.pathExtension.lowercased()) else {
            throw IPTVPlaylistError.fileReadFailed
        }
        let localURL = try copyFileToDocumentsIfNeeded(fileURL)
        return try await importLocalPlaylist(fileURL: localURL, name: name)
    }

    func importLocalPlaylist(fileURL: URL, name: String?) async throws -> IPTVPlaylist {
        guard let data = try? Data(contentsOf: fileURL),
              let content = Self.decodePlaylistData(data) else {
            throw IPTVPlaylistError.fileReadFailed
        }
        guard Self.isM3UContent(content) else { throw IPTVPlaylistError.invalidPlaylistContent }

        let sourceURL = Self.originalSourceURL(for: fileURL)
        let fallbackName = fileURL.deletingPathExtension().lastPathComponent
        let playlistName = name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? name! : fallbackName

        guard !Self.isHLSManifest(content) else { throw IPTVPlaylistError.unplayablePlaylist }

        var channels = parser.parse(m3uContent: content, baseURL: sourceURL)
            .filter { Self.isPlayableStreamURL($0.url) }
        guard !channels.isEmpty else { throw IPTVPlaylistError.unplayablePlaylist }

        // A device file is one video: it gets one card in VIDEOS (a playlist is what a link imports).
        guard channels.count == 1 else { throw IPTVPlaylistError.multipleVideos }
        if channels[0].duration <= 0, let url = URL(string: channels[0].url) {
            channels[0].duration = await Self.duration(of: url)
        }

        return try await savePlaylist(
            name: playlistName,
            url: sourceURL?.absoluteString ?? fileURL.absoluteString,
            source: .file,
            channels: channels
        )
    }

    /// Length in whole seconds, read from the file's header; -1 when it can't be read in time.
    private static func duration(of url: URL) async -> Int {
        let asset = AVURLAsset(url: url)
        return await withTaskGroup(of: Int.self) { group in
            group.addTask {
                guard let time = try? await asset.load(.duration), time.seconds.isFinite, time.seconds > 0 else { return -1 }
                return Int(time.seconds.rounded())
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                return -1
            }
            let first = await group.next() ?? -1
            group.cancelAll()
            return first
        }
    }

    func importSingleStream(name: String? = nil, url: String) async throws -> IPTVPlaylist {
        let streamURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let streamName = Self.normalizedName(name, fallbackURLString: streamURL)
        guard isValidRemoteURL(streamURL) else { throw IPTVPlaylistError.invalidURL }

        guard try await !repository.playlistExists(url: streamURL) else { throw IPTVPlaylistError.duplicateURL }

        guard Self.isLikelyPlaylistURL(streamURL) else {
            return try await saveSingleStream(name: streamName, url: streamURL)
        }

        let channels = try await downloadChannels(from: streamURL, defaultChannelName: streamName)
        return try await savePlaylist(name: streamName, url: streamURL, source: .stream, channels: channels)
    }

    // MARK: - Private: loading

    private func downloadChannels(from urlString: String, defaultChannelName: String? = nil) async throws -> [IPTVChannel] {
        guard let url = URL(string: urlString) else { throw IPTVPlaylistError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw IPTVPlaylistError.playlistRequestTimeout
        }

        guard let content = Self.decodePlaylistData(data), Self.isM3UContent(content) else {
            throw IPTVPlaylistError.invalidPlaylistContent
        }

        if Self.isHLSManifest(content) {
            let title = defaultChannelName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? defaultChannelName!
                : Self.fallbackName(from: url)
            var channel = IPTVChannel(title: title, url: url.absoluteString, groupTitle: "Stream")
            channel.duration = await Self.duration(of: url)
            return [channel]
        }

        let parsedChannels = parser.parse(m3uContent: content, baseURL: url)
        guard !parsedChannels.isEmpty else { throw IPTVPlaylistError.emptyPlaylist }

        let playableChannels = parsedChannels.filter { Self.isPlayableStreamURL($0.url) }
        guard !playableChannels.isEmpty else { throw IPTVPlaylistError.unplayablePlaylist }
        return playableChannels
    }

    private func loadXtreamChannels(
        serverURL: String,
        username: String,
        password: String
    ) async throws -> [IPTVChannel] {
        let loader = XtreamContentLoader(serverURL: serverURL, username: username, password: password)
        let box = ContinuationBox<[IPTVChannel]>()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                box.install(continuation)
                loader.load { result in
                    box.resume(with: result)
                }
            }
        } onCancel: {
            loader.cancel()
            // The loader stays silent once cancelled: finish the call here.
            box.resume(with: .failure(CancellationError()))
        }
    }

    private func copyFileToDocumentsIfNeeded(_ sourceURL: URL) throws -> URL {
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw IPTVPlaylistError.fileCopyFailed
        }

        let didAccessSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destinationURL = documentDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        if sourceURL.standardizedFileURL == destinationURL.standardizedFileURL {
            return sourceURL
        }

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw IPTVPlaylistError.fileCopyFailed
        }
        return destinationURL
    }

    private func isValidRemoteURL(_ value: String) -> Bool {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else {
            return false
        }
        
        return true
    }
    
    private func saveSingleStream(name streamName: String, url streamURL: String) async throws -> IPTVPlaylist {
        var channel = IPTVChannel(
            title: streamName,
            url: streamURL,
            groupTitle: "Stream"
        )
        // A live stream times out and stays -1 ("--:--"); a VOD link resolves, like a device file.
        if let url = URL(string: streamURL) {
            channel.duration = await Self.duration(of: url)
        }
        return try await savePlaylist(
            name: channel.title,
            url: streamURL,
            source: .stream,
            channels: [channel]
        )
    }
    
    private static func normalizedName(_ name: String?, fallbackURLString: String) -> String {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedName, !trimmedName.isEmpty {
            return trimmedName
        }
        
        if let url = URL(string: fallbackURLString) {
            return fallbackName(from: url)
        }
        
        return fallbackURLString
    }
    
    private static func isM3UContent(_ content: String) -> Bool {
        guard !isHTMLContent(content) else { return false }
        
        let lines = content
            .components(separatedBy: .newlines)
            .map {
                $0.replacingOccurrences(of: "\u{feff}", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
        
        guard let firstLine = lines.first?.uppercased() else { return false }
        return firstLine.hasPrefix("#EXTM3U")
        || lines.prefix(10).contains { $0.uppercased().hasPrefix("#EXTINF") }
    }
    
    private static func isHLSManifest(_ content: String) -> Bool {
        content.range(of: "#EXT-X-", options: [.caseInsensitive]) != nil
    }
    
    private static func isHTMLContent(_ content: String) -> Bool {
        let prefix = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(512)
            .lowercased()
        
        return prefix.hasPrefix("<!doctype")
        || prefix.hasPrefix("<html")
        || prefix.hasPrefix("<head")
        || prefix.hasPrefix("<body")
        || prefix.contains("<!doctype html")
        || prefix.contains("<html")
        || prefix.contains("<head")
        || prefix.contains("<body")
    }
    
    private static func isLikelyPlaylistURL(_ value: String) -> Bool {
        guard let url = URL(string: value) else { return false }
        return ["m3u", "m3u8", "w3u"].contains(url.pathExtension.lowercased())
    }
    
    private static func isPlayableStreamURL(_ value: String) -> Bool {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased() else {
            return false
        }
        
        if ["http", "https", "rtmp", "rtsp", "udp", "rtp", "mms", "ftp"].contains(scheme) {
            return true
        }
        
        if scheme == "file" {
            return FileManager.default.fileExists(atPath: url.path)
        }
        
        return false
    }
    
    private static func fallbackName(from url: URL) -> String {
        let title = url.deletingPathExtension().lastPathComponent
            .removingPercentEncoding?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title?.isEmpty == false ? title! : "Stream"
    }
    
    private static func decodePlaylistData(_ data: Data) -> String? {
        for encoding in [String.Encoding.utf8, .windowsCP1252, .isoLatin1, .ascii] {
            if let content = String(data: data, encoding: encoding) {
                return content
            }
        }
        return nil
    }
    
    private static func originalSourceURL(for fileURL: URL) -> URL? {
        let attributeName = "com.apple.metadata:kMDItemWhereFroms"
        let length = getxattr(fileURL.path, attributeName, nil, 0, 0, 0)
        guard length > 0 else { return nil }
        
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { buffer in
            getxattr(fileURL.path, attributeName, buffer.baseAddress, length, 0, 0)
        }
        guard result > 0,
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else {
            return nil
        }
        
        let values: [Any]
        if let array = plist as? [Any] {
            values = array
        } else {
            values = [plist]
        }
        
        return values
            .compactMap { $0 as? String }
            .compactMap(URL.init(string:))
            .first { url in
                guard let scheme = url.scheme?.lowercased() else { return false }
                return ["http", "https"].contains(scheme)
            }
    }
    
    private func normalizedXtreamServerURL(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let lowercased = trimmed.lowercased()
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return trimmed
        }
        return "http://\(trimmed)"
    }
}

/// Lets a callback-based API finish a `withCheckedThrowingContinuation` exactly once, from any thread.
private final class ContinuationBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?
    private var pending: Result<Value, Error>?

    func install(_ continuation: CheckedContinuation<Value, Error>) {
        lock.lock()
        if let pending {
            self.pending = nil
            lock.unlock()
            continuation.resume(with: pending)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func resume(with result: Result<Value, Error>) {
        lock.lock()
        guard let continuation else {
            // Cancelled before the continuation existed: keep the first result.
            if pending == nil { pending = result }
            lock.unlock()
            return
        }
        self.continuation = nil
        lock.unlock()
        continuation.resume(with: result)
    }
}
