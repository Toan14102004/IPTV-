//
//  RootViewAppearance.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

struct RootViewAppearance: ViewModifier {
    @Environment(\.injected) private var injected: DIContainer
    @State private var isActive: Bool = false
    let inspection = Inspection<Self>()

    func body(content: Content) -> some View {
        content
            .onReceive(stateUpdate) { isActive = $0 }
            .onReceive(inspection.notice) { inspection.visit(self, $0) }
    }

    private var stateUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.system.isActive)
    }
}
