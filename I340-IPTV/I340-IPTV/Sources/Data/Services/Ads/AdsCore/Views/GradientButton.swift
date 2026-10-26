//
//  GradientButton.swift
//  I340_IPTV
//

import UIKit

/// A `UIButton` whose own layer is a two-stop linear gradient — for the native ad
/// call-to-action button, which Figma ("Linear/Color 1") fills left-to-right from
/// `#2948D0` to `#5FDAFF`; a flat `backgroundColor` cannot reproduce that.
@IBDesignable
final class GradientButton: UIButton {
    @IBInspectable var startColor: UIColor = UIColor(hex: 0x2948D0) { didSet { updateColors() } }
    @IBInspectable var endColor: UIColor = UIColor(hex: 0x5FDAFF) { didSet { updateColors() } }

    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        updateColors()
    }

    private func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
}
