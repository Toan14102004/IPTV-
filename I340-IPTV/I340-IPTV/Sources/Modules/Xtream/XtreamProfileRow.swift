//
//  XtreamProfileRow.swift
//  I340_IPTV
//

import SwiftUI

/// Card for one Xtream profile: avatar, name, id, server, "updated on" and the "more" button.
struct XtreamProfileRow: View {
    let profile: XtreamProfileItem
    let onTap: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(profile.avatarName)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(Asset.Color.avatarBorder.color, lineWidth: 2))

            VStack(alignment: .leading, spacing: 0) {
                Text(profile.name)
                    .font(FontFamily.Poppins.medium.font(size: 18))
                    .foregroundColor(.white)
                Text("ID: \(profile.profileID)")
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(Asset.Color.textGray.color)
                Text(profile.serverURL)
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(Asset.Color.textGray.color)
                Text(profile.updatedText)
                    .font(FontFamily.Poppins.medium.font(size: 12))
                    .foregroundColor(Asset.Color.brandRed.color)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .actionMenuAnchor(id: profile.id)
        }
        .padding(.leading, 18)
        .padding(.trailing, Layout.Spacing.s)
        .frame(height: 98)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onTap)
    }
}
