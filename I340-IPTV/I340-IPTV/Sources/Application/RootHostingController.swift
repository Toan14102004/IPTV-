//
//  RootHostingController.swift
//  I340_IPTV
//

import SwiftUI
import UIKit

/// Window root: hosts the SwiftUI `RootView`. Fullscreen video asks for landscape through
/// `AppDelegate.orientationMask`.
final class RootHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        AppDelegate.share().orientationMask
    }

    override var shouldAutorotate: Bool { true }
}
