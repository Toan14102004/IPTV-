//
//  View+Toast.swift
//  I340_IPTV
//

import SwiftUI

extension View {
    /// Short message at the top of the screen; clears `message` after `duration`.
    func toast(message: Binding<String?>, duration: TimeInterval = 2) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    Text(message)
                        .font(FontFamily.Poppins.regular.font(size: 14))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Layout.Spacing.m)
                        .padding(.vertical, Layout.Spacing.s)
                        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: Layout.CornerRadius.medium))
                        .padding(.top, Layout.Spacing.s)
                        .padding(.horizontal, Layout.Spacing.m)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: message) {
                            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            withAnimation { self.message = nil }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: message)
    }
}
