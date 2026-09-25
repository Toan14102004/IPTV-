//
//  IPTVFavoriteChannelStore.swift
//  I340_IPTV
//
//  Created by Nguyen Dao Hung on 12/06/2026.
//

import Foundation

final class IPTVFavoriteChannelStore {
    static let shared = IPTVFavoriteChannelStore()
    
    private let storageKey = "iptv_favorite_channel_keys"
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    var favoriteKeys: Set<String> {
        Set(defaults.stringArray(forKey: storageKey) ?? [])
    }
    
    func isFavorite(_ channel: IPTVChannel) -> Bool {
        favoriteKeys.contains(Self.favoriteKey(for: channel))
    }

    func isFavorite(_ channel: IPTVChannel, in playlistID: String) -> Bool {
        favoriteKeys(for: playlistID).contains(Self.favoriteKey(for: channel))
    }

    func favoriteKeySet(in playlistID: String) -> Set<String> {
        favoriteKeys(for: playlistID)
    }
    
    @discardableResult
    func toggle(_ channel: IPTVChannel) -> Bool {
        var keys = favoriteKeys
        let key = Self.favoriteKey(for: channel)
        let isFavorite: Bool
        
        if keys.contains(key) {
            keys.remove(key)
            isFavorite = false
        } else {
            keys.insert(key)
            isFavorite = true
        }
        
        defaults.set(Array(keys), forKey: storageKey)
        return isFavorite
    }
    
    func remove(_ channel: IPTVChannel) {
        var keys = favoriteKeys
        keys.remove(Self.favoriteKey(for: channel))
        defaults.set(Array(keys), forKey: storageKey)
    }

    @discardableResult
    func toggle(_ channel: IPTVChannel, in playlistID: String) -> Bool {
        var keys = favoriteKeys(for: playlistID)
        let key = Self.favoriteKey(for: channel)
        let isFavorite: Bool
        
        if keys.contains(key) {
            keys.remove(key)
            isFavorite = false
        } else {
            keys.insert(key)
            isFavorite = true
        }
        
        defaults.set(Array(keys), forKey: storageKey(for: playlistID))
        return isFavorite
    }

    func remove(_ channel: IPTVChannel, in playlistID: String) {
        var keys = favoriteKeys(for: playlistID)
        keys.remove(Self.favoriteKey(for: channel))
        defaults.set(Array(keys), forKey: storageKey(for: playlistID))
    }

    func removeAll(in playlistID: String) {
        defaults.removeObject(forKey: storageKey(for: playlistID))
    }

    func favoriteChannels(from channels: [IPTVChannel], in playlistID: String) -> [IPTVChannel] {
        let keys = favoriteKeys(for: playlistID)
        return channels.filter { keys.contains(Self.favoriteKey(for: $0)) }
    }
    
    func removeAll() {
        defaults.removeObject(forKey: storageKey)
    }
    
    static func favoriteKey(for channel: IPTVChannel) -> String {
        let streamURL = channel.url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !streamURL.isEmpty {
            return "url:\(streamURL.lowercased())"
        }
        
        return "id:\(channel.id.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private func favoriteKeys(for playlistID: String) -> Set<String> {
        Set(defaults.stringArray(forKey: storageKey(for: playlistID)) ?? [])
    }

    private func storageKey(for playlistID: String) -> String {
        let accountID = playlistID.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(storageKey)_xtream_\(accountID)"
    }
}
