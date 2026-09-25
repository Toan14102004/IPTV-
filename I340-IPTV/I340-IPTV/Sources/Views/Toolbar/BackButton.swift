//
//  BackButton.swift
//  I340_IPTV
//

import SwiftUI

/// Arrow used by every screen header; `tint` differs per screen.
struct BackButton: View {
    var tint: Color = .white
    var size: CGFloat = 24
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Asset.Icon.icArrowLeft.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .frame(width: max(size, 44), height: max(size, 44))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
