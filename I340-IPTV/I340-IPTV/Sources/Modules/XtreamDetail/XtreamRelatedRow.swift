//
//  XtreamRelatedRow.swift
//  I340_IPTV
//

import SwiftUI

/// Card of a related channel under the Xtream player: poster, title, group and favorite heart.
struct XtreamRelatedRow: View {
    let channel: IPTVChannel
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RemoteImageView(urlString: channel.imageURL, placeholder: Asset.Icon.icXtreamMovies, contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: Layout.Spacing.xxs) {
                Text(channel.title)
                    .font(FontFamily.Poppins.medium.font(size: 20))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(channel.groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "Movies" : channel.groupTitle)
                    .font(FontFamily.Poppins.regular.font(size: 15))
                    .foregroundColor(Asset.Color.textGray.color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 96)
        .overlay(RoundedRectangle(cornerRadius: Layout.CornerRadius.large).stroke(Asset.Color.cardBorder.color, lineWidth: 1.2))
        .contentShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
        .onTapGesture(perform: onTap)
    }
}
