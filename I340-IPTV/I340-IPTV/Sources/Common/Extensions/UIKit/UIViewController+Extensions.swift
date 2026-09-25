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
    
    func showImageAlert(
        title : String? = nil,
        subtitle : String? = nil,
        image: UIImage? = nil,
        actionHandler: ((_ text: String?) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        
        //Insert image
        
        let customView = UIView()
        alert.view.addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 100).isActive = true
        customView.rightAnchor.constraint(equalTo: alert.view.rightAnchor, constant: -10).isActive = true
        customView.leftAnchor.constraint(equalTo: alert.view.leftAnchor, constant: 10).isActive = true
        customView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        alert.view.translatesAutoresizingMaskIntoConstraints = false
        alert.view.heightAnchor.constraint(equalToConstant: 320).isActive = true
                    
        let dogImage = UIImageView(frame: CGRect.zero)
        dogImage.image = image
        dogImage.translatesAutoresizingMaskIntoConstraints = false
        dogImage.layer.cornerRadius = 12
        dogImage.contentMode = .scaleAspectFill
        dogImage.layer.masksToBounds = true
        customView.addSubview(dogImage)
        
        let widthConstraint = NSLayoutConstraint(item: dogImage, attribute: .width, relatedBy: .equal,
                                                 toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 120)

        let heightConstraint = NSLayoutConstraint(item: dogImage, attribute: .height, relatedBy: .equal,
                                                  toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 120)

        let xConstraint = NSLayoutConstraint(item: dogImage, attribute: .centerX, relatedBy: .equal, toItem: customView, attribute: .centerX, multiplier: 1, constant: 0)

        let yConstraint = NSLayoutConstraint(item: dogImage, attribute: .centerY, relatedBy: .equal, toItem: customView, attribute: .centerY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])
                
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
