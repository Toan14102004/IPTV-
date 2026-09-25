//
//  SearchBar.swift
//  I340_IPTV
//

import SwiftUI

/// Pill-shaped search field: magnifier, white placeholder and a clear button while editing.
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Asset.Color.textGray.color)
                .frame(width: 24, height: 24)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundColor(.white)
            )
            .font(FontFamily.Poppins.regular.font(size: 16))
            .foregroundColor(.white)
            .tint(.brand)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .focused(isFocused)
            .onSubmit { isFocused.wrappedValue = false }

            if isFocused.wrappedValue && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Asset.Color.textGray.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Layout.Spacing.sm)
        .frame(height: 48)
        .background(Asset.Color.fieldBackground.color)
        .clipShape(Capsule())
    }
}
