//
//  AlertController.swift
//  I340_IPTV
//
//  Created by HaoLK on 09/12/2020.
//

import Foundation
import UIKit

// MARK: - UIAlertController extension to show alerts with custom design.
extension UIAlertController {

    func show() {
        present(animated: true) {
            // TODO: solve layout issue
        }
    }

    func present(animated: Bool, completion: (() -> Void)?) {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            if rootVC.presentedViewController is UIAlertController {
                return
            }
            presentFromController(controller: rootVC, animated: animated, completion: completion)
        }
    }

    private func presentFromController(controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if let navVC = controller as? UINavigationController,
            let visibleVC = navVC.visibleViewController {
            presentFromController(controller: visibleVC, animated: animated, completion: completion)
        } else if let tabVC = controller as? UITabBarController,
            let selectedVC = tabVC.selectedViewController {
            presentFromController(controller: selectedVC, animated: animated, completion: completion)
        } else if let presentedVc = controller.presentedViewController {
            presentFromController(controller: presentedVc, animated: animated, completion: completion)
        } else {
            if controller is UIAlertController {
                guard let controllerPresenter = controller.presentingViewController else {
                    return
                }

                DispatchQueue.main.async {
                    controller.dismiss(animated: true) {
                        controllerPresenter.present(self, animated: animated, completion: completion)
                    }
                }

                return
            }

            DispatchQueue.main.async {
                controller.present(self, animated: animated, completion: completion)
            }
        }
    }

    static func showDefaultTwoButtonAlert(withTitle title: String?, message: String, leftButtonTitle: String?, rightButtonTitle: String?,
                                          leftAction: ((UIAlertAction) -> Void)?, rightAction: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let leftActionButton = UIAlertAction(title: leftButtonTitle, style: .cancel, handler: leftAction)
        let rightActionButton = UIAlertAction(title: rightButtonTitle, style: .default, handler: rightAction)

        alert.addAction(leftActionButton)
        alert.addAction(rightActionButton)

        alert.show()
    }

    static func showMessage(_ message: String?, action: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        let actionButton = UIAlertAction(title: "OK", style: .cancel, handler: action)

        alert.addAction(actionButton)

        alert.show()
    }

}

extension UIAlertAction {
    func setTitleColor(_ color: UIColor) {
        self.setValue(color, forKey: "titleTextColor")
    }
}

extension UIAlertController {
    
    //Set title font and title color
    func setTitle(font: UIFont?, color: UIColor?) {
        guard let title = self.title else { return }
        let attributeString = NSMutableAttributedString(string: title)//1
        if let titleFont = font {
            attributeString.addAttributes([NSAttributedString.Key.font : titleFont],//2
                                          range: NSMakeRange(0, title.utf8.count))
        }
        
        if let titleColor = color {
            attributeString.addAttributes([NSAttributedString.Key.foregroundColor : titleColor],//3
                                          range: NSMakeRange(0, title.utf8.count))
        }
        self.setValue(attributeString, forKey: "attributedTitle")//4
    }
    
    //Set message font and message color
    func setMessage(font: UIFont?, color: UIColor?) {
        guard let message = self.message else { return }
        let attributeString = NSMutableAttributedString(string: message)
        if let messageFont = font {
            attributeString.addAttributes([NSAttributedString.Key.font : messageFont],
                                          range: NSMakeRange(0, message.utf8.count))
        }
        
        if let messageColorColor = color {
            attributeString.addAttributes([NSAttributedString.Key.foregroundColor : messageColorColor],
                                          range: NSMakeRange(0, message.utf8.count))
        }
        self.setValue(attributeString, forKey: "attributedMessage")
    }
}
