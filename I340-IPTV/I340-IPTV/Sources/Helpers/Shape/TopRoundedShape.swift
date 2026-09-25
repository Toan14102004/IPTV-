//
//  TopRoundedShape.swift
//  I340_IPTV
//

import SwiftUI
import UIKit

/// Rectangle with only the top corners rounded (iOS 15 has no `UnevenRoundedRectangle`).
struct TopRoundedShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
        )
    }
}
