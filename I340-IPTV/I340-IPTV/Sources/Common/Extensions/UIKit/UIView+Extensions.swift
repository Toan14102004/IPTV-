//
//  UIView+Extensions.swift
//  I340_IPTV
//
//  Created by Dmnhat on 01/12/2021.
//

import Foundation
import UIKit

final class BindableGestureRecognizer: UITapGestureRecognizer {
    private var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }
    
    @objc private func execute() {
        action()
    }
}

extension UIView {
    @IBInspectable
    //Corner radius of view
    var cornerRadiusXIB: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    func showTappedAnimation(_ completionBlock: @escaping () -> Void) {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .curveLinear,
                       animations: { [weak self] in
            self?.transform = CGAffineTransform.init(scaleX: 0.95, y: 0.95)
        }) {  (done) in
            UIView.animate(withDuration: 0.1,
                           delay: 0,
                           options: .curveLinear,
                           animations: { [weak self] in
                self?.transform = CGAffineTransform.init(scaleX: 1, y: 1)
            }) { [weak self] (_) in
                self?.isUserInteractionEnabled = true
                completionBlock()
            }
        }
    }
    
    func setShadowColor(color: UIColor,width: Double, height: Double, radius: Double, opacity: Float = 1) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = .init(width: width, height: height)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = CGFloat(radius)
    }
    
    func roundCorners(corners: [Corners], radius: CGFloat) {
        //self.clipsToBounds = true
        layer.cornerRadius = radius
        if #available(iOS 11.0, *) {
            layer.maskedCorners = Corners.getMaskCorner(corner: corners)
        }else {
            // Fallback on earlier versions
        }
    }
    
    /// A discrete gesture recognizer that interprets single or multiple taps.
    /// - Parameters:
    /// - tapNumber: The number of taps necessary for gesture recognition.
    /// - closure: A selector that identifies the method implemented by the target to handle the gesture recognized by the receiver. The action selector must conform to the signature described in the class overview. NULL is not a valid value.
    func addTapGesture(tapNumber: Int = 1, _ closure: (() -> Void)?) {
        guard let closure = closure else { return }
        
        let tap = BindableGestureRecognizer(action: closure)
        tap.numberOfTapsRequired = tapNumber
        addGestureRecognizer(tap)
        
        isUserInteractionEnabled = true
    }
    
    func collapse() {
        translatesAutoresizingMaskIntoConstraints = false
        
        for constraint in constraints {
            if constraint.firstAnchor == heightAnchor {
                constraint.isActive = false
            }
        }
        
        let newHeight = heightAnchor.constraint(equalToConstant: 0)
        newHeight.isActive = true
        
        isHidden = true
        alpha = 0
    }
    
    func expand(height: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        
        for constraint in constraints {
            if constraint.firstAnchor == heightAnchor {
                constraint.isActive = false
            }
        }
        
        let newHeight = heightAnchor.constraint(equalToConstant: height)
        newHeight.isActive = true
        
        isHidden = false
        alpha = 1
        
        superview?.layoutIfNeeded()
    }
}

extension UILabel {
    func addIcon(text: String, icon: UIImage?) {
        // Create Attachment
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = icon
        // Set bound to reposition
        let imageOffsetY: CGFloat = 2
        imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: 4, height: 4)
        // Create string with attachment
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        // Initialize mutable string
        let completeText = NSMutableAttributedString(string: "")
        // Add image to mutable string
        completeText.append(attachmentString)
        // Add your text to mutable string
        let textAfterIcon = NSAttributedString(string: text)
        completeText.append(textAfterIcon)
        self.textAlignment = .left
        self.attributedText = completeText
    }

    func applyGradient(colors: [UIColor]) {
        guard let text = self.text else { return }

        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        // Create text mask
        let maskLabel = UILabel(frame: bounds)
        maskLabel.text = text
        maskLabel.font = font
        maskLabel.textAlignment = textAlignment

        gradientLayer.mask = maskLabel.layer

        // Remove old gradient if exists
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        layer.addSublayer(gradientLayer)
    }
}


enum Corners {
    
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    
    func getCorner() -> CACornerMask {
        switch self {
        case .topLeft :
            return CACornerMask.layerMinXMinYCorner
        case .topRight :
            return CACornerMask.layerMaxXMinYCorner
        case .bottomLeft:
            return CACornerMask.layerMinXMaxYCorner
        case .bottomRight:
            return CACornerMask.layerMaxXMaxYCorner
        }
    }
    
    static func getMaskCorner(corner: [Corners]) -> CACornerMask {
        var maskCorner:CACornerMask!
        switch corner.count {
        case 1:
            maskCorner = [ corner[0].getCorner() ]
        case 2:
            maskCorner = [ corner[0].getCorner(), corner[1].getCorner() ]
        case 3:
            maskCorner = [ corner[0].getCorner(), corner[1].getCorner() , corner[2].getCorner() ]
        case 4:
            maskCorner = [ corner[0].getCorner(), corner[1].getCorner() , corner[2].getCorner() , corner[3].getCorner() ]
        default:
            maskCorner = [ corner[0].getCorner() ]
        }
        return maskCorner
    }
}
