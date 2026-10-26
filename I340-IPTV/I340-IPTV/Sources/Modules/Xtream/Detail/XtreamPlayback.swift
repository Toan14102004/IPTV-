//
//  XtreamPlayback.swift
//  I340_IPTV
//

import Foundation

extension IPTVPlaylist {
    /// A playlist so an Xtream movie, series or channel plays on the Play Video screen.
    /// The header shows its category, the player its own title.
    ///
    /// `related` is the category's other channels, so "Next Channel" on a playback-failure
    /// dialog has somewhere to go. When `channel` is not part of it (e.g. called without a
    /// category context), the playlist falls back to just that one channel.
    static func xtreamPlayback(of channel: IPTVChannel, in related: [IPTVChannel] = []) -> IPTVPlaylist {
        let group = channel.groupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let channels = related.contains(where: { $0.id == channel.id }) ? related : [channel]
        return IPTVPlaylist(
            id: channel.id,
            name: group.isEmpty ? channel.title : group,
            url: channel.url,
            source: .xtream,
            channels: channels
        )
    }
}
