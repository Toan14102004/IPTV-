//
//  ImportXtreamView.swift
//  I340_IPTV
//

import SwiftUI

/// Form that adds an Xtream Codes profile: avatar, name, server, username and password.
struct ImportXtreamView: View {
    @StateObject private var viewModel: ViewModel

    init(onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(onBack: onBack))
    }

    var body: some View {
        ZStack {
            BaseView(background: Color.background1) {
                VStack(spacing: 0) {
                    ScreenHeader(
                        title: viewModel.title,
                        onBack: viewModel.didTapBack,
                        onFavorite: viewModel.didTapFavorites,
                        onHelp: viewModel.didTapHelp,
                        onPremium: viewModel.premiumAction
                    )

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            avatarButton

                            fields
                                .padding(.top, Layout.Spacing.m)

                            Button(action: viewModel.didTapHowToUse) {
                                Text(viewModel.howToUseTitle)
                                    .underline()
                                    .font(Typography.bodyLarge)
                                    .foregroundStyle(Color.primary1)
                                    .frame(height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, Layout.Spacing.m)

                            addButton
                                .padding(.top, Layout.Spacing.s)
                        }
                        .padding(.horizontal, Layout.Spacing.m)
                        .padding(.bottom, Layout.Spacing.l)
                    }
                    .scrollDismissesKeyboardIfAvailable()
                    .disabled(viewModel.isImporting)

                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
            // The keyboard covers the ad instead of pushing it up; the fields sit above it anyway.
            .ignoresSafeArea(.keyboard, edges: .bottom)

            if viewModel.isImporting {
                LoadingDialogView(
                    title: viewModel.loadingTitle,
                    message: viewModel.loadingMessage,
                    closeTitle: viewModel.closeTitle,
                    onClose: viewModel.cancelImport
                )
                .transition(.opacity)
            }
        }
        .trackScreen("ImportXtream")
        .popup(isPresented: $viewModel.isAvatarSheetPresented) {
            AvatarSheet(viewModel: viewModel)
        } customize: { params in
            params.bottomPopup()
                .closeOnTap(false)
                .closeOnTapOutside(true)
                .dragToDismiss(true)
                .backgroundColor(Color.black.opacity(0.2))
        }
        .sheet(isPresented: $viewModel.isPhotoPickerPresented) {
            AvatarPhotoPicker(onPick: viewModel.didPickPhoto)
        }
        .popup(isPresented: $viewModel.isErrorPresented) {
            AppDialogView(
                image: Asset.Image.imgInvalidSource,
                title: viewModel.failedTitle,
                message: viewModel.errorMessage ?? "",
                secondaryTitle: viewModel.cancelTitle,
                primaryTitle: viewModel.tryAgainTitle,
                onSecondary: viewModel.dismissError,
                onPrimary: viewModel.retry,
                onClose: viewModel.dismissError
            )
        } customize: { params in
            params.centerPopup().closeOnTapOutside(true).backgroundColor(.dialogDim)
        }
        .suppressesAppOpenAd()
    }
}

// MARK: - Sections

private extension ImportXtreamView {
    var avatarButton: some View {
        Button(action: viewModel.didTapAvatar) {
            XtreamAvatarImage(name: viewModel.avatar)
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) {
                    Asset.Image.imgXtreamCameraBadge.image
                        .resizable()
                        .frame(width: 28, height: 28)
                }
        }
        .buttonStyle(.plain)
    }

    var fields: some View {
        VStack(spacing: Layout.Spacing.m) {
            FormInputField(
                title: viewModel.nameTitle,
                isRequired: true,
                icon: Asset.Icon.icImportFieldName,
                placeholder: viewModel.namePlaceholder,
                text: $viewModel.name
            )
            FormInputField(
                title: viewModel.serverTitle,
                isRequired: true,
                icon: Asset.Icon.icImportFieldLink,
                placeholder: viewModel.serverPlaceholder,
                text: $viewModel.serverURL,
                hint: viewModel.serverHint,
                keyboardType: .URL
            )
            FormInputField(
                title: viewModel.usernameTitle,
                isRequired: true,
                icon: Asset.Icon.icImportFieldUser,
                placeholder: viewModel.usernamePlaceholder,
                text: $viewModel.username,
                keyboardType: .asciiCapable
            )
            FormInputField(
                title: viewModel.passwordTitle,
                isRequired: true,
                icon: Asset.Icon.icImportFieldLock,
                placeholder: viewModel.passwordPlaceholder,
                text: $viewModel.password,
                isSecure: !viewModel.isPasswordVisible
            ) {
                Button {
                    viewModel.isPasswordVisible.toggle()
                } label: {
                    (viewModel.isPasswordVisible ? Asset.Image.Movies.icPasswordXtreamOpen : Asset.Icon.icImportFieldEyeClosed)
                        .image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text2)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var addButton: some View {
        Button(action: viewModel.didTapAdd) {
            HStack(spacing: Layout.Spacing.s) {
                Asset.Icon.icPlus.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(viewModel.addTitle)
                    .font(Typography.subtitleSmall)
            }
            .foregroundStyle(viewModel.canAdd ? Color.text4 : Color.text3)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(viewModel.canAdd ? Color.primary1 : Color.neutral1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdd || viewModel.isImporting)
    }
}

// MARK: - Avatar sheet

/// Figma "Select your avatar": 520pt white sheet, 3 columns of 96pt circles, 44pt buttons.
private struct AvatarSheet: View {
    @ObservedObject var viewModel: ImportXtreamView.ViewModel

    private let size: CGFloat = 96
    private var avatars: [String] { ImportXtreamView.ViewModel.avatars.map(\.name) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(viewModel.avatarTitle)
                    .font(Typography.subtitleMedium)
                    .foregroundStyle(Color.text1)
                Text(viewModel.avatarSubtitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)

            VStack(spacing: 12) {
                row([nil] + avatars.prefix(2).map { Optional($0) })
                row(avatars[2..<5].map { Optional($0) })
                row(avatars[5..<8].map { Optional($0) })
            }
            .padding(.top, 24)

            HStack(spacing: 12) {
                Button(action: viewModel.cancelAvatar) {
                    Text(viewModel.cancelTitle)
                        .font(Typography.subtitleSmall)
                        .foregroundStyle(Color.primary1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary1, lineWidth: 1))
                }
                Button(action: viewModel.saveAvatar) {
                    Text(viewModel.saveChangesTitle)
                        .font(Typography.subtitleSmall)
                        .foregroundStyle(Color.text4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            .padding(.bottom, Layout.Spacing.l)
        }
        .padding(.horizontal, Layout.Spacing.m)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            Button(action: viewModel.cancelAvatar) {
                // 24pt icon with a 12pt glyph (Figma "Close Icon"); the padding only widens the tap area.
                Asset.Icon.icDialogClose.image
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
        }
        .background(
            TopRoundedShape(radius: 32)
                .fill(Color.white)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// One row of three; `nil` is the "+" tile that opens the photo library.
    private func row(_ items: [String?]) -> some View {
        HStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 { Spacer(minLength: 0) }
                if let item {
                    avatarButton(item)
                } else {
                    addTile
                }
            }
        }
    }

    private var addTile: some View {
        Button(action: viewModel.didTapAddPhoto) {
            Circle()
                .fill(Color.neutral1)
                .frame(width: size, height: size)
                .overlay(
                    Asset.Icon.icPlus.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.text1)
                        .frame(width: 24, height: 24)
                )
        }
        .buttonStyle(.plain)
    }

    private func avatarButton(_ name: String) -> some View {
        let isSelected = viewModel.draftAvatar == name
        return Button {
            viewModel.draftAvatar = name
        } label: {
            XtreamAvatarImage(name: name)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().inset(by: -1).stroke(isSelected ? Color.primary1 : .clear, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Asset.Image.imgAvatarCheck.image
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 20, height: 20)
                            .background(Color.accent1, in: Circle())
                            .offset(x: 6.5, y: -7)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
