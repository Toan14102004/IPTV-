//
//  UIViewController.swift
//  I340_IPTV
//
//  Created by Dmnhat on 18/10/2021.
//

import Foundation
import Loaf
import UIKit

extension UIViewController {
    func showInputDialog(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Add",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showToast(
        message: String
    ) {
        Loaf(message, location: .top, sender: self).show(.short)
    }

    func addChildToView(_ child: UIViewController, toView view: UIView) {
        addChild(child)
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func showOneButtonAlert(
        title : String? = nil,
        subtitle : String? = nil,
        actionHandler: ((_ text: String?) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        //Add more actions as you see fit
        self.present(alert, animated: true, completion: nil)
    }
    
    func showRateAlert(cancelHandler: (() -> Swift.Void)? = nil) {
        if !UserDefaultManager.shared().isRated {
            let alert = UIAlertController(title: "Please give us your feedback", message: "Your opinion is very important to us. We appreciate your feedback and will use it to evaluate changes and make improvements in our app.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: {
                _ in
                cancelHandler?()
            }))

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action:UIAlertAction) in
                navigateToRateScreen()
            }))
            //Add more actions as you see fit
            self.present(alert, animated: true, completion: nil)
        } else {
            cancelHandler?()
        }
    }
    
    func showBottomSheetAction(title: String?, message: String?, sourceView: UIView, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        actions.forEach { action in
            alertController.addAction(action)
        }

        alertController.popoverPresentationController?.sourceView = sourceView
        alertController.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.maxY, width: 0, height: 0)
        alertController.popoverPresentationController?.permittedArrowDirections = [.down]
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(
        title : String? = nil,
        subtitle : String? = nil,
        cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
        actionHandler: ((_ text: String?) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .destructive, handler: cancelHandler))
        
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        //Add more actions as you see fit
        self.present(alert, animated: true, completion: nil)
    }
    
    var visibleTopViewController: UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.topViewController?.visibleTopViewController
        } else if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.visibleTopViewController
        } else if let presentedViewController = presentedViewController {
            return presentedViewController.visibleTopViewController
        } else {
            return self
        }
    }
}
