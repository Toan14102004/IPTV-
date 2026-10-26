//
//  UIColor+Extensions.swift
//  ContentBlockSafari
//
//  Created by HaoLK on 8/19/20.
//  Copyright © 2020 Fox. All rights reserved.
//

import UIKit

extension UIColor {
    /// Creates a color object using the hex integer RGB component values.
    /// - Parameters:
    ///   - hex: 0xRRGGBB
    convenience init(hex: Int) {
      self.init(hex: hex, alpha: 1)
    }

    /// Creates a color object using the specified opacity and hex integer RGB component values.
    /// - Parameters:
    ///   - hex: 0xRRGGBB
    ///   - alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0. Alpha values below 0.0 are interpreted as 0.0, and values above 1.0 are interpreted as 1.0.
    convenience init(hex: Int, alpha: Double) {
      self.init(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: CGFloat(alpha)
      )
    }
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha:1)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        var hexWithoutSymbol: String = hex
        if hexWithoutSymbol.hasPrefix("#") {
            hexWithoutSymbol = hex.substring(from: 1)
        }
        
        let scanner = Scanner(string: hexWithoutSymbol)
        var hexInt : UInt64 = 0
        scanner.scanHexInt64(&hexInt)
        
        self.init(red: CGFloat((hexInt & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((hexInt & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(hexInt & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}
