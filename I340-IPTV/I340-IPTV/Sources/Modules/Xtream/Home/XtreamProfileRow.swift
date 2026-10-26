//
//  XtreamProfileRow.swift
//  I340_IPTV
//

import SwiftUI

/// Card of an Xtream profile: tile, name, channel count and favorite / delete buttons.
struct XtreamProfileRow: View {
    let profile: XtreamProfileItem
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Asset.Image.imgXtreamItem.image
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                Text(profile.name)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)

                HStack(spacing: Layout.Spacing.s) {
                    Asset.Icon.icPlaylistChannels.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text2)
                        .frame(width: 20, height: 20)
                    Text(subtitle)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.text2)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PlaylistCardActions(isFavorite: isFavorite, onFavorite: onFavorite, onDelete: onDelete)
        }
        .padding(Layout.Spacing.sm)
        .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
        .shadow(.card)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
    }

    /// The channel count is only known once the profile has been loaded; until then show the account.
    private var subtitle: String {
        guard profile.channelCount > 0 else { return profile.profileID }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let count = formatter.string(from: NSNumber(value: profile.channelCount)) ?? "\(profile.channelCount)"
        let format = "playlist_channels_count".localized(fallback: "%d channels")
            .replacingOccurrences(of: "%d", with: "%@")
        return String(format: format, count)
    }
}
