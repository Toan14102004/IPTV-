//
//  AddPlaylistMenuView.swift
//  I340_IPTV
//

import SwiftUI

struct AddPlaylistMenuView: View {
    let close: (_ completion: (() -> Void)?) -> Void
    let onSelect: (PlaylistAddMenuOption) -> Void
    let onHowToUse: () -> Void

    private let options: [PlaylistAddMenuOption] = [.importPlaylistURL, .importFromDevice, .playSingleStream, .importXtreamCodeAPI]
    private let columns = [
        GridItem(.flexible(), spacing: Layout.Spacing.s),
        GridItem(.flexible(), spacing: Layout.Spacing.s),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: 0xDBE0E9))
                .frame(width: 44, height: 4)
                .padding(.top, Layout.Spacing.s)

            header
                .padding(.top, 20)

            LazyVGrid(columns: columns, spacing: Layout.Spacing.s) {
                ForEach(options, id: \.self) { option in
                    Button {
                        close { onSelect(option) }
                    } label: {
                        VStack(spacing: Layout.Spacing.s) {
                            option.importImage.image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            Text(option.importTitleKey.localized(fallback: option.importFallbackTitle))
                                .font(Typography.labelMedium)
                                .foregroundStyle(Color.primary1)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Layout.Spacing.sm)
                        .frame(height: 86)
                        .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
                        .shadow(.card)
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, Layout.Spacing.m)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, Layout.Spacing.m)
        .frame(maxWidth: .infinity)
        .background(
            TopRoundedShape(radius: 32)
                .fill(Color.background1)
                .ignoresSafeArea(edges: .bottom)
        )
        .suppressesAppOpenAd()
    }

    private var header: some View {
        HStack(spacing: Layout.Spacing.s) {
            Text("import_choose_title".localized(fallback: "Choose Import"))
                .font(Typography.subtitleLarge)
                .foregroundStyle(Color.text1)

            Button {
                InterstitialGuard.perform { close(onHowToUse) }
            } label: {
                Asset.Icon.icHelpCircle.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.text2)
                    .frame(width: 24, height: 24)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

private extension PlaylistAddMenuOption {
    var importImage: ImageAsset {
        switch self {
        case .importPlaylistURL: Asset.Image.imgImportM3u
        case .importFromDevice: Asset.Image.imgImportFile
        case .playSingleStream: Asset.Image.imgImportStream
        case .importXtreamCodeAPI: Asset.Image.imgImportXtream
        }
    }

    var importTitleKey: String {
        switch self {
        case .importPlaylistURL: "import_option_playlist_url"
        case .importFromDevice: "import_option_device"
        case .playSingleStream: "import_option_stream"
        case .importXtreamCodeAPI: "import_option_xtream"
        }
    }

    var importFallbackTitle: String {
        switch self {
        case .importPlaylistURL: "Playlist URL"
        case .importFromDevice: "Load From Device"
        case .playSingleStream: "Play Single Stream"
        case .importXtreamCodeAPI: "Xtream Codes API"
        }
    }
}
