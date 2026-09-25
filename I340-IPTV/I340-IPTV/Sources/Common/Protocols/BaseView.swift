//
//  BaseView.swift
//  I340_IPTV
//

import SwiftUI

/// Root container for every SwiftUI screen: dark canvas, hidden system back button,
/// full-size layout. Wrap each screen body in it.
struct BaseView<Content: View>: View {
    @Environment(\.dismiss) var dismiss

    var background: AnyShapeStyle
    let content: Content

    init(background: some ShapeStyle = Asset.Color.colorBg.color, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.background = AnyShapeStyle(background)
    }

    var body: some View {
        ZStack {
            content
        }
        .foregroundStyle(.white)
        .colorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { Rectangle().fill(background).ignoresSafeArea() }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .contentShape(Rectangle())
    }
}
