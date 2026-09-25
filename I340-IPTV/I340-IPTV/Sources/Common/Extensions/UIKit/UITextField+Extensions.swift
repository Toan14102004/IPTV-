//
//  UITextField+Extensions.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/3/26.
//

import Foundation
import UIKit

extension UITextField {
    func setLeftIcon(_ image: UIImage, padding: CGFloat = 10) {
        let iconSize: CGFloat = 24
        let containerWidth = iconSize + padding * 2
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: iconSize))
        
        let iconView = UIImageView(frame: CGRect(x: padding, y: 0, width: iconSize, height: iconSize))
        iconView.image = image
        iconView.contentMode = .scaleAspectFit
        containerView.addSubview(iconView)
        
        self.leftView = containerView
        self.leftViewMode = .always
    }
}
