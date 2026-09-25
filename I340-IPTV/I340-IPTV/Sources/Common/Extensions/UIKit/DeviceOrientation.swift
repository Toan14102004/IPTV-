//
//  DeviceOrientation.swift
//  I340_IPTV
//

import UIKit

/// Rotates the app between portrait and landscape (used by fullscreen video).
enum DeviceOrientation {
    static func setLandscape(_ isLandscape: Bool) {
        let mask: UIInterfaceOrientationMask = isLandscape ? .landscapeRight : .portrait
        AppDelegate.share().orientationMask = mask

        let topController = UIApplication.shared.topMostViewController
        let rootController = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController

        if #available(iOS 16.0, *) {
            topController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            topController?.navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            rootController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            let scene = topController?.view.window?.windowScene
            scene?.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        } else {
            let orientation: UIInterfaceOrientation = isLandscape ? .landscapeRight : .portrait
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
