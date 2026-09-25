//
//  ChannelList.swift
//  I340_IPTV
//

import Foundation

/// A list of channels passed as a navigation value. Hashing only looks at the size and the ends
/// of the list, so pushing a screen with thousands of channels stays cheap.
struct ChannelList: Hashable, Codable {
    var channels: [IPTVChannel]

    init(_ channels: [IPTVChannel]) {
        self.channels = channels
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channels.count)
        hasher.combine(channels.first?.id)
        hasher.combine(channels.last?.id)
    }

    static func == (lhs: ChannelList, rhs: ChannelList) -> Bool {
        lhs.channels.count == rhs.channels.count
            && lhs.channels.first?.id == rhs.channels.first?.id
            && lhs.channels.last?.id == rhs.channels.last?.id
    }
}
