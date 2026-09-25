//
//  UIApplication+TopViewController.swift
//  I340_IPTV
//

import UIKit

extension UIApplication {
    /// The view controller currently on screen, looking through modals and navigation stacks.
    var topMostViewController: UIViewController? {
        let keyWindow = windows.first { $0.isKeyWindow }
        return keyWindow?.rootViewController?.fx_topMost()
    }
}

extension UIApplication {
    /// Presents the system share sheet over the top screen.
    func share(items: [Any]) {
        guard let presenter = topMostViewController else { return }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = presenter.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0
        )
        presenter.present(activityVC, animated: true)
    }
}
