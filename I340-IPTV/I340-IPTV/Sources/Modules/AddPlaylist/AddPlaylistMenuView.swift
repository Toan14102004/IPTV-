//
//  AddPlaylistMenuView.swift
//  I340_IPTV
//

import SwiftUI

/// "Menu" bottom sheet listing the ways to add a playlist.
struct AddPlaylistMenuView: View {
    let close: (_ completion: (() -> Void)?) -> Void
    let onSelect: (PlaylistAddMenuOption) -> Void
    let onHowToUse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Asset.Color.handleGray.color)
                .frame(width: 60, height: 6)
                .padding(.top, Layout.Spacing.s)

            header
                .padding(.top, 36)

            VStack(spacing: 0) {
                ForEach(PlaylistAddMenuOption.allCases, id: \.self) { option in
                    Button {
                        close { onSelect(option) }
                    } label: {
                        HStack(spacing: Layout.Spacing.sm) {
                            option.icon.image
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)

                            Text(title(for: option))
                                .font(FontFamily.Poppins.medium.font(size: 14))
                                .foregroundColor(Asset.Color.textPrimary.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.trailing, Layout.Spacing.m)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Layout.Spacing.l)
            .padding(.top, Layout.Spacing.sm)

            Button {
                InterstitialGuard.perform { close(onHowToUse) }
            } label: {
                Text("playlist_menu_how_to_use".localized(fallback: "How to use?"))
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(.brand)
                    .underline()
                    .frame(height: 24)
            }
            .buttonStyle(.plain)
            .padding(.top, Layout.Spacing.m)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(
            TopRoundedShape(radius: 32)
                .fill(Asset.Color.sheetBackground.color)
                .ignoresSafeArea(edges: .bottom)
        )
        .suppressesAppOpenAd()
    }

    private var header: some View {
        ZStack {
            Text("playlist_menu_title".localized(fallback: "Menu"))
                .font(FontFamily.Poppins.medium.font(size: 20))
                .foregroundColor(.white)

            HStack {
                Button {
                    InterstitialGuard.perform { close(nil) }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.leading, 6)
                Spacer()
            }
        }
        .frame(height: 24)
    }

    private func title(for option: PlaylistAddMenuOption) -> String {
        option.titleKey.localized(fallback: option.fallbackTitle)
    }
}
