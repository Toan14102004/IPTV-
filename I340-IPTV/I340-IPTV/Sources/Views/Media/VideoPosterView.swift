//
//  VideoPosterView.swift
//  I340_IPTV
//

import Kingfisher
import SwiftUI

/// Poster for a video entry: its declared image if any, otherwise a frame grabbed from the
/// stream itself (cached by Kingfisher like any other image), falling back to a generic
/// placeholder when there is no image and no frame could be generated (e.g. rtsp/udp streams,
/// which AVFoundation cannot decode).
struct VideoPosterView: View {
    let imageURL: String
    /// The stream's own URL, used to generate a frame when there is no declared poster image.
    let streamURL: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        if !imageURL.isEmpty {
            RemoteImageView(urlString: imageURL, placeholder: Asset.Image.imgPlaylistItem, contentMode: contentMode)
        } else if let frameSource {
            KFImage(source: frameSource)
                .placeholder { placeholderImage }
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholderImage
        }
    }

    /// AVFoundation only reads http(s)-reachable assets; other schemes fall through to the placeholder.
    private var frameSource: Source? {
        guard let streamURL,
              let url = URL(string: streamURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return nil }
        return .provider(AVAssetImageDataProvider(assetURL: url, seconds: 1))
    }

    private var placeholderImage: some View {
        Asset.Image.imgPlaylistItem.image
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }
}
