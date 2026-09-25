//
//  MediaTabs.swift
//  I340_IPTV
//

import SwiftUI

/// Movies / Series / Live TV switcher: black capsule with a red gradient border and a glowing
/// gradient capsule behind the selected tab.
struct MediaTabs: View {
    enum Tab: Int, CaseIterable {
        case movies
        case series
        case liveTV

        var titleKey: String {
            switch self {
            case .movies: "main_xtream_movies"
            case .series: "main_xtream_series"
            case .liveTV: "main_xtream_live_tv"
            }
        }

        var systemImage: String {
            switch self {
            case .movies: "film"
            case .series: "tv"
            case .liveTV: "play.tv"
            }
        }
    }

    let selected: Tab
    let onSelect: (Tab) -> Void

    private let gradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0, blue: 0.1), Color(red: 1, green: 0, blue: 0.35), Color(red: 0.4, green: 0, blue: 0.1)],
        startPoint: .leading,
        endPoint: .trailing
    )
    private let borderGradient = LinearGradient(
        colors: [Color(red: 0.35, green: 0, blue: 0.1), Color(red: 1, green: 0, blue: 0.35), Color(red: 0.35, green: 0, blue: 0.1)],
        startPoint: .leading,
        endPoint: .trailing
    )

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { onSelect(tab) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 13, weight: .medium))
                        Text(tab.titleKey.localized)
                            .font(FontFamily.Poppins.medium.font(size: 14))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if tab == selected {
                            Capsule()
                                .fill(gradient)
                                .shadow(color: Color.pink.opacity(0.8), radius: 9)
                                .matchedGeometryEffect(id: "selection", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.Spacing.s)
        .frame(height: 48)
        .background(Color.black)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(borderGradient, lineWidth: 1.5))
    }
}
