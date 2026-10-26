//
//  ContentViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension ContentView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            /// Remote config asks users to move to another app (`appID` is its App Store id).
            case reinstallRequired(appID: String)
        }

        /// Sheets of the "add" flow, drawn over the tabs and the tab bar.
        enum Overlay: Equatable {
            case addMenu
            case addStream
            /// `owner` is the tab that handles what the form produces.
            case addPlaylist(mode: AddPlaylistMode, owner: Tab)
        }

        var alert: Alert?
        var overlay: Overlay?
    }
}
