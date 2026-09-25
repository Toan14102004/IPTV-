//
//  UIImage+Extensions.swift
//  I340_IPTV
//
//  Created by Mac mini M2 on 25/4/25.
//

import Foundation
import UIKit

extension UIImage {
    func resizeTo(w: Double, h: Double) -> UIImage {
        let newSize = CGSize(width: w, height: h)
        // Important thing here
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let image = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
            
        return image.withRenderingMode(renderingMode)
    }
}
