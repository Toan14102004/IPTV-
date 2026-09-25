//
//  XtreamPosterView.swift
//  I340_IPTV
//

import SwiftUI

/// Poster with a favorite toggle and a two-line title.
struct XtreamPosterView: View {
    let channel: IPTVChannel
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.s) {
            RemoteImageView(urlString: channel.imageURL, placeholder: nil, contentMode: .fill)
                .frame(width: 122, height: 174)
                .background(Asset.Color.fieldBackground.color)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.medium))
                .overlay(alignment: .topTrailing) {
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.black.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                    .padding(Layout.Spacing.s)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

            Text(channel.title)
                .font(FontFamily.Poppins.medium.font(size: 12))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 122, height: 32, alignment: .topLeading)
        }
        .frame(width: 122)
    }
}

/// Large poster of the series carousel with a "Watch now" pill.
struct XtreamFeaturedView: View {
    let channel: IPTVChannel
    let onTap: () -> Void

    var body: some View {
        RemoteImageView(urlString: channel.imageURL, placeholder: nil, contentMode: .fill)
            .frame(width: 224, height: 318)
            .background(Asset.Color.fieldBackground.color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottom) {
                HStack(spacing: Layout.Spacing.xs) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("xtream_watch_now".localized)
                        .font(FontFamily.Poppins.medium.font(size: 13))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .frame(height: 36)
                .background(Capsule().fill(Asset.Color.brandRedBadge.color))
                .padding(.bottom, Layout.Spacing.sm)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}
