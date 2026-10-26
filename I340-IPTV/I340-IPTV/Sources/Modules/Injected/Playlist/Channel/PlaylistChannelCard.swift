//
//  PlaylistChannelCard.swift
//  I340_IPTV
//

import SwiftUI

/// Card of one channel in a playlist (Figma "card_tv"): 90×60 logo, title, group and a chevron.
struct PlaylistChannelCard: View {
    let channel: IPTVChannel
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            // The artwork stays a background so its fill size never widens the card.
            Color.clear
                .frame(width: 90, height: 60)
                .background(
                    RemoteImageView(urlString: channel.imageURL, placeholder: Asset.Icon.icChannelDefault, contentMode: .fill)
                )
                .background(Color.neutral1)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                Text(channel.title.isEmpty ? channel.url : channel.title)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.text1)
                    .lineLimit(2)
                Text(channel.groupTitle.isEmpty ? "Movies" : channel.groupTitle)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.text2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Asset.Icon.icSettingsChevron.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.text2)
                .frame(width: 24, height: 24)
        }
        .padding(Layout.Spacing.sm)
        .frame(minHeight: 86)
        .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
        .shadow(.card)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}
