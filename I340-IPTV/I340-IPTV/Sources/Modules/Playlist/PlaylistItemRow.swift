//
//  PlaylistItemRow.swift
//  I340_IPTV
//

import SwiftUI

/// Card for one playlist: artwork, name, "updated … • N channels" and the "more" button.
struct PlaylistItemRow: View {
    let playlist: IPTVPlaylist
    let subtitle: String
    let onTap: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Asset.Icon.icPlaylistItemDefault.image
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: Layout.Spacing.xxs) {
                Text(playlist.name)
                    .font(FontFamily.Poppins.medium.font(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(FontFamily.Poppins.regular.font(size: 12))
                    .foregroundColor(Asset.Color.textSubtitle.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .actionMenuAnchor(id: playlist.id)
        }
        .padding(.leading, Layout.Spacing.sm)
        .padding(.trailing, 10)
        .frame(height: 84)
        .background(Asset.Color.cardBackground.color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onTap)
    }
}
