//
//  FormInputField.swift
//  I340_IPTV
//

import SwiftUI

/// Labeled input of the new design (Figma "Input"): title with an optional red "*", a rounded
/// field with a leading icon, and a hint line under it that turns green once the value is valid.
enum FormFieldStatus: Equatable {
    case normal
    case valid
    case invalid
}

struct FormInputField<Trailing: View>: View {
    typealias Status = FormFieldStatus

    let title: String
    var isRequired = false
    let icon: ImageAsset
    let placeholder: String
    @Binding var text: String
    var hint: String?
    var status: Status = .normal
    var keyboardType: UIKeyboardType = .default
    var isSecure = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.s) {
            HStack(spacing: Layout.Spacing.xs) {
                Text(title)
                    .foregroundStyle(Color.text2)
                if isRequired {
                    Text("*")
                        .foregroundStyle(Color.accent2)
                }
            }
            .font(Typography.labelMedium)

            HStack(spacing: Layout.Spacing.s) {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.text2)
                    .frame(width: 24, height: 24)

                field
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.text1)
                    .tint(Color.primary1)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(isPlainText ? .sentences : .never)
                    .autocorrectionDisabled(!isPlainText)

                trailing()
            }
            .padding(Layout.Spacing.m)
            .frame(height: 56)
            .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(.textField)

            if let hint {
                HStack(spacing: Layout.Spacing.xs) {
                    if status == .valid {
                        Asset.Image.imgImportValidMark.image
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    Text(hint)
                        .font(Typography.labelSmall)
                        .foregroundStyle(hintColor)
                }
            }
        }
    }

    /// Names and titles are prose; URLs, accounts and passwords must keep exactly what was typed.
    private var isPlainText: Bool { keyboardType == .default && !isSecure }

    @ViewBuilder
    private var field: some View {
        let prompt = Text(placeholder).foregroundColor(Color.text2)
        if isSecure {
            SecureField("", text: $text, prompt: prompt)
        } else {
            TextField("", text: $text, prompt: prompt)
        }
    }

    private var borderColor: Color {
        switch status {
        case .normal: .neutralStroke
        case .valid: .accent1
        case .invalid: .accent2
        }
    }

    private var hintColor: Color {
        switch status {
        case .normal: .text3
        case .valid: .accent1
        case .invalid: .accent2
        }
    }
}

extension FormInputField where Trailing == EmptyView {
    init(
        title: String,
        isRequired: Bool = false,
        icon: ImageAsset,
        placeholder: String,
        text: Binding<String>,
        hint: String? = nil,
        status: Status = .normal,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        self.init(
            title: title,
            isRequired: isRequired,
            icon: icon,
            placeholder: placeholder,
            text: text,
            hint: hint,
            status: status,
            keyboardType: keyboardType,
            isSecure: isSecure,
            trailing: { EmptyView() }
        )
    }
}

extension View {
    /// Dragging the scroll view hides the keyboard (iOS 16+).
    @ViewBuilder
    func scrollDismissesKeyboardIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }
}
