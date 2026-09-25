//
//  View+Analytics.swift
//  I340_IPTV
//

import SwiftUI

extension View {
    /// Sends a `screen_view` event each time the view appears.
    func trackScreen(_ name: String) -> some View {
        onAppear { AnalyticsService.shared.log(.screenView(name)) }
    }
}
