//
//  XtreamPosterView.swift
//  I340_IPTV
//

import SwiftUI

/// Card of a channel / movie / series (Figma "channels"): artwork with a favorite badge, title and category.
struct XtreamPosterView: View {
    let channel: IPTVChannel
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.s) {
            // The artwork stays a background so its fill size never widens the card.
            Color.clear
                .frame(width: 134, height: 98)
                .background(
                    RemoteImageView(urlString: channel.imageURL, placeholder: Asset.Image.imgPlaylistItem, contentMode: .fill)
                )
                .background(Color.neutral1)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) { favoriteButton }

            VStack(alignment: .leading, spacing: 0) {
                Text(channel.title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)
                Text(channel.groupTitle)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.text2)
                    .lineLimit(1)
            }
            .frame(width: 134, height: 36, alignment: .topLeading)
        }
        .padding(.horizontal, Layout.Spacing.s)
        .padding(.top, Layout.Spacing.s)
        .padding(.bottom, 12)
        .frame(width: 150, alignment: .leading)
        .background(Color.background1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
        .shadow(.card)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
    }

    private var favoriteButton: some View {
        Button(action: onFavorite) {
            Group {
                if isFavorite {
                    Asset.Icon.icPlaylistFavoriteFilled.image.resizable()
                } else {
                    Asset.Icon.icPlaylistFavorite.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 12, height: 12)
            .frame(width: 20, height: 20)
            .background(Color.black.opacity(0.5), in: Circle())
            .overlay(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 1)
        .padding(.trailing, 1)
    }
}
