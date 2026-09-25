//
//  BottomSheetContainer.swift
//  I340_IPTV
//

import SwiftUI

/// Dimmed backdrop with a sheet that slides up from the bottom. `onDismiss` is called once the
/// slide-out animation has finished, so the hosting controller can be dismissed without animation.
struct BottomSheetContainer<Content: View>: View {
    var dimOpacity: Double = 0.7
    var dismissesOnDimTap = true
    let onDismiss: (_ completion: (() -> Void)?) -> Void
    @ViewBuilder let content: (_ close: @escaping (_ completion: (() -> Void)?) -> Void) -> Content

    @State private var isShown = false
    @State private var isClosing = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(isShown ? dimOpacity : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    if dismissesOnDimTap { close(nil) }
                }

            if isShown {
                content(close)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.28)) { isShown = true }
        }
    }

    private func close(_ completion: (() -> Void)?) {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(.easeIn(duration: 0.22)) { isShown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss(completion)
        }
    }
}
