//
//  HubView.swift
//  I340_IPTV
//

import SwiftUI

/// Room tab: type the 6-character code of a room to join it.
struct HubView: View {
    @StateObject private var viewModel = ViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        BaseView(background: Color.white) {
            VStack(spacing: 0) {
                ScreenHeader(title: "main_hub".localized(fallback: "Room"))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Layout.Spacing.l) {
                        NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                            MediumNativeAdView(frame: .zero)
                        }

                        VStack(spacing: Layout.Spacing.m) {
                            heading
                            codeField
                            shortcuts
                        }

                        joinButton
                    }
                    .padding(.bottom, Layout.Spacing.l)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("Room")
        .toast(message: $viewModel.toast)
        .popup(isPresented: unavailableBinding) {
            unavailableDialog
        } customize: { params in
            params.centerPopup().closeOnTap(false).closeOnTapOutside(true).backgroundColor(.dialogDim)
        }
    }

    private var heading: some View {
        VStack(spacing: Layout.Spacing.xs) {
            Text("room_join_title".localized(fallback: "Have a room code?"))
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
            Text("room_join_message".localized(fallback: "Enter the 6-character room code to join."))
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text1)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Layout.Spacing.m)
    }

    /// Six boxes drawn over a hidden text field that owns the keyboard.
    private var codeField: some View {
        ZStack {
            HStack(spacing: Layout.Spacing.s) {
                ForEach(Array(viewModel.characters.enumerated()), id: \.offset) { index, character in
                    codeBox(character, isCurrent: isFocused && index == viewModel.code.count)
                }
            }
            .frame(maxWidth: CGFloat(ViewModel.codeLength) * 50 + CGFloat(ViewModel.codeLength - 1) * Layout.Spacing.s)

            TextField("", text: $viewModel.code)
                .focused($isFocused)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.join)
                .onSubmit(viewModel.join)
                .foregroundColor(.clear)
                .tint(.clear)
                .opacity(0.02)
        }
        .padding(.horizontal, Layout.Spacing.m)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    private func codeBox(_ character: String, isCurrent: Bool) -> some View {
        Text(character)
            .font(Typography.subtitleLarge.weight(.bold))
            .foregroundStyle(Color.text1)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.background1, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isCurrent ? Color.primary1 : Color.neutral1, lineWidth: 1)
            )
    }

    private var shortcuts: some View {
        HStack {
            if let lastCode = viewModel.lastCode {
                Button(action: viewModel.useLastCode) {
                    HStack(spacing: Layout.Spacing.xs) {
                        Asset.Icon.icRoomHistory.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(lastCode)
                            .font(Typography.bodySmall)
                    }
                    .foregroundStyle(Color.text2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.primary2, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            if viewModel.code.isEmpty {
                Button(action: viewModel.paste) {
                    HStack(spacing: 6) {
                        Asset.Icon.icCopy.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("room_paste".localized(fallback: "Paste"))
                            .font(Typography.bodySmall)
                    }
                    .foregroundStyle(Color.text2)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: viewModel.clear) {
                    HStack(spacing: 6) {
                        Asset.Icon.icRoomClear.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("room_clear".localized(fallback: "Clear"))
                            .font(Typography.bodySmall)
                    }
                    .foregroundStyle(Color.text2)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 28)
        .padding(.horizontal, Layout.Spacing.m)
    }

    private var joinButton: some View {
        let isEnabled = viewModel.isValid && !viewModel.isJoining
        return Button {
            isFocused = false
            viewModel.join()
        } label: {
            (viewModel.isValid ? Asset.Image.imgRoomJoinOn : Asset.Image.imgRoomJoinOff).image
                .resizable()
                .scaledToFit()
                .frame(width: 151, height: 65)
                .overlay(alignment: .top) {
                    Group {
                        if viewModel.isJoining {
                            ProgressView().tint(Color.text4)
                        } else {
                            Text("room_join_button".localized(fallback: "Join").uppercased())
                                .font(FontFamily.Poppins.bold.font(size: 20))
                                .foregroundStyle(viewModel.isValid ? Color.text4 : Color.text3)
                        }
                    }
                    .frame(height: 47)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var unavailableBinding: Binding<Bool> {
        Binding(
            get: { viewModel.unavailableCode != nil },
            set: { if !$0 { viewModel.unavailableCode = nil } }
        )
    }

    private var unavailableDialog: some View {
        AppDialogView(
            image: Asset.Image.imgRoomOops,
            title: "room_unavailable_title".localized(fallback: "Room Unavailable"),
            message: String(
                format: "room_unavailable_message".localized(
                    fallback: "The room code “%@” is invalid or no longer available."
                ),
                viewModel.unavailableCode ?? ""
            ),
            secondaryTitle: "cancel".localized(fallback: "Cancel"),
            primaryTitle: "room_edit_code".localized(fallback: "Edit code"),
            onSecondary: {
                viewModel.clear()
                viewModel.editCode()
            },
            onPrimary: {
                viewModel.editCode()
                isFocused = true
            },
            secondaryColor: Color.text2
        )
    }
}

#Preview {
    HubView()
        .preview()
}
