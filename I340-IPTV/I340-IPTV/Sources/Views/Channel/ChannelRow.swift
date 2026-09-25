//
//  ChannelRow.swift
//  I340_IPTV
//

import SwiftUI

/// Card for one channel: logo, title, group, favorite heart and the "more" button.
struct ChannelRow: View {
    let channel: IPTVChannel
    let isFavorite: Bool
    /// Id the "more" menu is anchored to (see `actionMenuAnchor`); nil hides the button.
    var menuAnchorID: String?
    let onTap: () -> Void
    let onFavorite: () -> Void
    var onMore: (() -> Void)?

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            RemoteImageView(urlString: channel.imageURL, placeholder: Asset.Icon.icChannelDefault)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.sm))

            VStack(alignment: .leading, spacing: Layout.Spacing.xxs) {
                Text(channel.title.isEmpty ? channel.url : channel.title)
                    .font(FontFamily.Poppins.medium.font(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(channel.groupTitle.isEmpty ? "Movies" : channel.groupTitle)
                    .font(FontFamily.Poppins.regular.font(size: 12))
                    .foregroundColor(Asset.Color.textSubtitle.color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Layout.Spacing.xs) {
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let onMore {
                    Button(action: onMore) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .actionMenuAnchor(id: menuAnchorID ?? channel.id)
                }
            }
        }
        .padding(.leading, Layout.Spacing.sm)
        .padding(.trailing, Layout.Spacing.s)
        .frame(height: 84)
        .background(Asset.Color.cardBackground.color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onTap)
    }
}
