//
//  RootViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension RootView {
    struct Coordinator: BaseCoordinator {
        /// Screens pushed on the root `FlowStack` (they cover the tab bar).
        enum Navigation: BaseNavigation {
            case settings
            case playlistChannels(playlist: IPTVPlaylist)
            case playlistFavorites
            case playlistList(section: PlaylistSection)
            case importPlaylist(tab: ImportPlaylistTab)
            case importXtream
            case playlistPlayer(playlist: IPTVPlaylist, channel: IPTVChannel)
            case playlistGroup(playlist: IPTVPlaylist, channel: IPTVChannel)
            case playVideo(playlist: IPTVPlaylist)
            case watchRoom(code: String)
            case xtreamFavorites(playlist: IPTVPlaylist?)
            case xtreamDetail(channel: IPTVChannel, related: ChannelList, playlistID: String?)
        }

        enum FullScreen: BaseFullScreen {
            case guide
            case paywall
            case language
            case web(url: String)
        }
    }
}
