//
//  FormFieldStyle.swift
//  I340_IPTV
//

import SwiftUI

/// Label above a form field; a red asterisk marks required fields.
struct FormFieldTitle: View {
    let title: String
    var isRequired = false

    var body: some View {
        Group {
            if isRequired {
                Text(title + " ").foregroundColor(Asset.Color.textGray.color) + Text("*").foregroundColor(.brand)
            } else {
                Text(title).foregroundColor(Asset.Color.textGray.color)
            }
        }
        .font(FontFamily.Poppins.regular.font(size: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    /// Rounded, bordered box for a text field.
    func formFieldBox(background: Color = Asset.Color.fieldBackgroundDark.color, cornerRadius: CGFloat = Layout.CornerRadius.sm) -> some View {
        self
            .font(FontFamily.Poppins.regular.font(size: 14))
            .foregroundColor(.white)
            .tint(.brand)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, Layout.Spacing.sm)
            .frame(height: 50)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Asset.Color.cardBorder.color, lineWidth: 1))
    }
}
