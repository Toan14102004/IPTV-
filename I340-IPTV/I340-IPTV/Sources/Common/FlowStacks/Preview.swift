//
//  Preview.swift
//  I340_IPTV
//

import Foundation
import SwiftUI

extension View {
    /// Wraps a view in a `FlowStack` so previews can push/present like the real app.
    public func preview() -> some View {
        modifier(PreviewModifier())
    }
}

struct PreviewModifier: ViewModifier {
    @State var path = FlowPath()

    func body(content: Content) -> some View {
        FlowStack($path, withNavigation: true) {
            content
                .modifier(NavigatorModifier())
        }
    }
}
