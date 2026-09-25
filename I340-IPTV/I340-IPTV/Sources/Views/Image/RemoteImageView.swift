//
//  RemoteImageView.swift
//  I340_IPTV
//

import Kingfisher
import SwiftUI

/// Image loaded from a URL string (cached by Kingfisher), showing `placeholder` while it loads
/// and when the string is empty or not a URL (nil placeholder: nothing).
struct RemoteImageView: View {
    let urlString: String
    let placeholder: ImageAsset?
    var contentMode: SwiftUI.ContentMode = .fit

    var body: some View {
        if !urlString.isEmpty, let url = URL(string: urlString) {
            KFImage(url)
                .placeholder { placeholderImage }
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholderImage
        }
    }

    @ViewBuilder
    private var placeholderImage: some View {
        if let placeholder {
            placeholder.image
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.clear
        }
    }
}
