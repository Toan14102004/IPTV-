//
//  View+NavigationBar.swift
//  I340_IPTV
//

import SwiftUI

extension View {
    /// The screens draw their own headers: hide the system navigation bar (iOS 15 and later).
    @ViewBuilder
    func hidesNavigationBar() -> some View {
        if #available(iOS 16.0, *) {
            self.toolbar(.hidden, for: .navigationBar)
        } else {
            self.navigationBarHidden(true)
        }
    }
}
