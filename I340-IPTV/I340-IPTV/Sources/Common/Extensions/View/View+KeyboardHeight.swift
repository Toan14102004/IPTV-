//
//  View+KeyboardHeight.swift
//  I340_IPTV
//

import SwiftUI

extension View {
    /// Reports the keyboard's height (0 when hidden) as it shows, resizes or hides. Used by
    /// screens presented from an `.overlay`, which get no automatic keyboard avoidance.
    func onKeyboardHeightChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let overlap = max(0, UIScreen.main.bounds.height - frame.origin.y)
            action(overlap)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            action(0)
        }
    }
}
