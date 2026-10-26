//
//  RenameSheetView.swift
//  I340_IPTV
//

import SwiftUI

/// Rename card of the new design (Figma "rename"): title, labelled text field, Cancel and Save.
/// Present it with `.popup(item:)` and
/// `params.centerPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDimLight)`.
struct RenameSheetView: View {
    let title: String
    /// Label above the field.
    let placeholder: String
    let continueTitle: String
    let emptyNameMessage: String
    let onClose: () -> Void
    let onContinue: (String) -> Void

    @State private var name: String
    @State private var toastMessage: String?
    @FocusState private var isFocused: Bool

    init(
        title: String,
        placeholder: String,
        continueTitle: String,
        emptyNameMessage: String,
        currentName: String,
        onClose: @escaping () -> Void,
        onContinue: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.continueTitle = continueTitle
        self.emptyNameMessage = emptyNameMessage
        self.onClose = onClose
        self.onContinue = onContinue
        _name = State(initialValue: currentName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Layout.Spacing.m)

            Text(placeholder)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.text2)
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.bottom, Layout.Spacing.s)

            TextField("", text: $name)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.text1)
                .tint(Color.primary1)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .padding(.horizontal, Layout.Spacing.m)
                .frame(height: 56)
                .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.neutralStroke, lineWidth: 1))
                .shadow(.card)
                .padding(.horizontal, Layout.Spacing.m)

            HStack(spacing: Layout.Spacing.sm) {
                Button(action: onClose) {
                    Text("cancel".localized(fallback: "Cancel"))
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.text2, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: submit) {
                    Text(continueTitle)
                        .font(Typography.subtitleSmall)
                        .foregroundStyle(Color.text4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.top, Layout.Spacing.l)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.background1, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, Layout.Spacing.m)
        .toast(message: $toastMessage)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true }
        }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            toastMessage = emptyNameMessage
            return
        }
        onContinue(trimmed)
    }
}
