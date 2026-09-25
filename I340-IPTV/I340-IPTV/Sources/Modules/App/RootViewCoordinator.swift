//
//  RootViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension RootView {
    struct Coordinator: BaseCoordinator {
        /// Screens pushed on the root `FlowStack` (they cover the Main tab bar).
        enum Navigation: BaseNavigation {
            case settings
            case playlistChannels(playlist: IPTVPlaylist)
            case playlistFavorites
            case playlistPlayer(playlist: IPTVPlaylist, channel: IPTVChannel)
            case xtreamFavorites(playlist: IPTVPlaylist?)
            case xtreamDetail(channel: IPTVChannel, related: ChannelList, playlistID: String?)
        }

        /// Screens presented over everything.
        enum FullScreen: BaseFullScreen {
            case guide
            case paywall
            case language
            case web(url: String)
        }
    }
}
