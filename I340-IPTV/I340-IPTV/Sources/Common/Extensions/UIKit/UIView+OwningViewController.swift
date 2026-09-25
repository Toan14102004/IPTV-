//
//  UIView+OwningViewController.swift
//  I340_IPTV
//

import UIKit

extension UIView {
    /// The closest view controller in the responder chain (for a view embedded in SwiftUI,
    /// that is the hosting controller).
    var owningViewController: UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return nil
    }
}

extension UIViewController {
    /// True if `other` is this controller or one of its descendants.
    func isSelfOrAncestor(of other: UIViewController) -> Bool {
        var current: UIViewController? = other
        while let controller = current {
            if controller === self { return true }
            current = controller.parent
        }
        return false
    }
}
