//
//  RenameSheetView.swift
//  I340_IPTV
//

import SwiftUI

/// Bottom sheet with a single text field. Present it with `.popup(item:)` and
/// `params.bottomPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDim)`.
struct RenameSheetView: View {
    let title: String
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
            ZStack(alignment: .top) {
                Capsule()
                    .fill(Asset.Color.dividerGray.color)
                    .frame(width: 60, height: 6)
                    .padding(.top, Layout.Spacing.s)

                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(Asset.Color.textGray.color)
                            .frame(width: 28, height: 28)
                    }
                    .padding(.top, Layout.Spacing.m)
                    .padding(.trailing, 20)
                }
            }
            .frame(height: 52)

            Text(title)
                .font(FontFamily.Poppins.medium.font(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, Layout.Spacing.l)

            TextField("", text: $name, prompt: Text(placeholder).foregroundColor(Color.white.opacity(0.4)))
                .font(FontFamily.Poppins.regular.font(size: 14))
                .foregroundColor(.white)
                .tint(Asset.Color.accentBlue.color)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .padding(.horizontal, Layout.Spacing.m)
                .frame(height: 50)
                .background(Asset.Color.separator.color)
                .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.large))
                .padding(.horizontal, Layout.Spacing.l)
                .padding(.top, Layout.Spacing.s)

            Button(action: submit) {
                Text(continueTitle)
                    .font(FontFamily.Poppins.medium.font(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.gradient(cornerRadius: Layout.CornerRadius.large))
            .padding(.horizontal, Layout.Spacing.l)
            .padding(.top, 40)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 244)
        .background(
            TopRoundedShape(radius: 32).fill(Asset.Color.sheetSurface.color).ignoresSafeArea(edges: .bottom)
        )
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
