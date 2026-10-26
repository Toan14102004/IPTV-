//
//  View+DismissKeyboard.swift
//  I340_IPTV
//

import SwiftUI
import UIKit

extension View {
    /// Tapping anywhere not already claimed by a button, text field, etc. resigns the keyboard.
    /// Works for any `@FocusState`-driven field without needing its binding.
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}
