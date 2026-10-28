//
//  PlaylistComponents.swift
//  I340_IPTV
//

import SwiftUI

struct PlaylistSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: Layout.Spacing.s) {
            Asset.Icon.icPlaylistSearch.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.text2)
                .frame(width: 24, height: 24)

            TextField(
                "",
                text: $text,
                prompt: Text("playlist_search_placeholder".localized(fallback: "Search Playlist")).foregroundColor(Color.text2)
            )
            .font(Typography.bodyMedium)
            .foregroundStyle(Color.text1)
            .tint(Color.primary1)
            .autocorrectionDisabled()
            .submitLabel(.search)
        }
        .padding(Layout.Spacing.m)
        .frame(height: 56)
        .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
        .shadow(.textField)
    }
}

struct PlaylistSectionHeader: View {
    let section: PlaylistSection
    var onSeeAll: (() -> Void)?

    var body: some View {
        HStack(spacing: Layout.Spacing.s) {
            section.icon.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.text1)
                .frame(width: 24, height: 24)

            Text(section.titleKey.localized(fallback: section.fallbackTitle))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.text1)

            Spacer(minLength: 0)

            if let onSeeAll {
                Button(action: onSeeAll) {
                    HStack(spacing: Layout.Spacing.xs) {
                        Text("playlist_see_all".localized(fallback: "See all"))
                            .font(Typography.labelSmall)
                        Asset.Icon.icPlaylistSeeAll.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .foregroundStyle(Color.primary1)
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PlaylistCard: View {
    let playlist: IPTVPlaylist
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Asset.Image.imgPlaylistItem.image
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                Text(playlist.name)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)

                HStack(spacing: Layout.Spacing.s) {
                    Asset.Icon.icPlaylistChannels.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text2)
                        .frame(width: 20, height: 20)
                    Text(playlist.source == .file ? playlist.videoSubtitle : playlist.channelCountText)
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
}

/// Grid card of a playlist file (VIDEOS): artwork of its first title, name, duration and a "more" menu.
struct VideoCard: View {
    let playlist: IPTVPlaylist
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        // The poster stays a background so its fill size never widens the card.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: PlaylistGrid.cardHeight)
            .background(poster)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.45),
                        .init(color: .black.opacity(0.8), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .bottom) { info }
            .background(Color.text1)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
            .shadow(.card)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture(perform: onTap)
    }

    /// The real length when known, otherwise a LIVE badge instead of a meaningless "--:--".
    @ViewBuilder
    private var durationOrLiveBadge: some View {
        if (playlist.channels.first?.duration ?? 0) > 0 {
            Text(playlist.videoSubtitle)
                .font(Typography.labelSmall)
                .lineLimit(1)
        } else {
            HStack(spacing: 4) {
                Circle().fill(Color.roomLeave).frame(width: 6, height: 6)
                Text("player_live".localized(fallback: "LIVE"))
                    .font(FontFamily.Poppins.semiBold.font(size: 11))
            }
        }
    }

    private var info: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: Layout.Spacing.xs) {
                Text(playlist.name)
                    .font(Typography.bodyLarge)
                    .lineLimit(1)
                durationOrLiveBadge
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(action: onFavorite) {
                    Text(isFavorite
                         ? "video_menu_favorite_remove".localized(fallback: "Remove from Favorites")
                         : "video_menu_favorite_add".localized(fallback: "Add to Favorites"))
                }
                Button(role: .destructive, action: onDelete) {
                    Text("video_menu_delete".localized(fallback: "Delete"))
                }
            } label: {
                Asset.Icon.icMoreVertical.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 32, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .foregroundStyle(Color.text4)
        .padding(.leading, Layout.Spacing.sm)
        .padding(.trailing, Layout.Spacing.xs)
        .padding(.bottom, Layout.Spacing.sm)
    }

    private var poster: some View {
        VideoPosterView(
            imageURL: playlist.channels.first?.imageURL ?? "",
            streamURL: playlist.channels.first?.url,
            contentMode: .fill
        )
    }
}

struct AddPlaylistDashedCard: View {
    var height: CGFloat = PlaylistGrid.cardHeight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Layout.Spacing.xs) {
                Asset.Icon.icPlus.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("playlist_add_playlist".localized(fallback: "Add Playlist"))
                    .font(Typography.subtitleSmall)
            }
            .foregroundStyle(Color.text3)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(hex: 0xD8D8D8), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum PlaylistGrid {
    static let cardHeight: CGFloat = 210
    static let columns = [
        GridItem(.flexible(), spacing: Layout.Spacing.sm),
        GridItem(.flexible(), spacing: Layout.Spacing.sm),
    ]
}

struct PlaylistCardActions: View {
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Button(action: onFavorite) {
                Group {
                    if isFavorite {
                        Asset.Icon.icPlaylistFavoriteFilled.image.resizable()
                    } else {
                        Asset.Icon.icPlaylistFavorite.image
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(Color.text2)
                    }
                }
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Asset.Icon.icPlaylistDelete.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.text2)
                    .frame(width: 24, height: 24)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
