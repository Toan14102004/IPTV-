//
//  DeleteDialogView.swift
//  I340_IPTV
//

import SwiftUI

/// "Are you sure you want to delete…?" dialog of the new design (Figma "Delete"): red trash
/// illustration, title, message, an outlined Cancel and a red Delete.
struct DeleteDialogView: View {
    var title = "playlist_delete_channel_title".localized(fallback: "Are you sure you want to delete this channel?")
    var message = "playlist_delete_undone_message".localized(fallback: "This action cannot be undone.")
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        AppDialogView(
            image: Asset.Image.imgDeleteChannel,
            imageHeight: 58,
            imageSpacing: Layout.Spacing.m,
            title: title,
            message: message,
            secondaryTitle: "cancel".localized(fallback: "Cancel"),
            primaryTitle: "playlist_action_delete".localized(fallback: "Delete"),
            onSecondary: onCancel,
            onPrimary: onDelete,
            secondaryColor: Color.text2,
            primaryColor: Color.roomLeave
        )
    }
}

extension Color {
    /// Dim behind the light dialogs of the new design (Figma overlay, 20% black).
    static let dialogDimLight = Color.black.opacity(0.2)
}
