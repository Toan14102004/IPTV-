//
//  ImportPlaylistView.swift
//  I340_IPTV
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportPlaylistView: View {
    @StateObject private var viewModel: ViewModel

    init(tab: ImportPlaylistTab, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(tab: tab, onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: viewModel.title,
                    onBack: viewModel.didTapBack,
                    onHelp: viewModel.didTapHelp,
                    onPremium: viewModel.premiumAction
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        tabs

                        fields
                            .padding(.top, Layout.Spacing.l)

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
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: playlistFileTypes,
            onCompletion: viewModel.didPickFile
        )
        .popup(item: $viewModel.alert) { item in
            switch item {
            case .invalidSource:
                AppDialogView(
                    image: Asset.Image.imgInvalidSource,
                    title: viewModel.invalidTitle,
                    message: viewModel.invalidMessage,
                    secondaryTitle: viewModel.cancelTitle,
                    primaryTitle: viewModel.tryAgainTitle,
                    onSecondary: viewModel.dismissAlert,
                    onPrimary: viewModel.retry,
                    onClose: viewModel.dismissAlert
                )
            case .unreachableConfirm:
                AppDialogView(
                    image: Asset.Image.imgInvalidSource,
                    title: viewModel.unreachableTitle,
                    message: viewModel.unreachableMessage,
                    secondaryTitle: viewModel.cancelTitle,
                    primaryTitle: viewModel.saveAnywayTitle,
                    onSecondary: viewModel.dismissAlert,
                    onPrimary: viewModel.confirmAddAnyway,
                    onClose: viewModel.dismissAlert
                )
            }
        } customize: { params in
            params.centerPopup().closeOnTapOutside(true).backgroundColor(.dialogDim)
        }
        .suppressesAppOpenAd()
    }

    private var playlistFileTypes: [UTType] {
        let types = ["m3u", "m3u8", "w3u"].compactMap { UTType(filenameExtension: $0) }
        return types.isEmpty ? [.data] : types
    }
}

// MARK: - Sections

private extension ImportPlaylistView {
    var tabs: some View {
        HStack(spacing: Layout.Spacing.s) {
            ForEach(ImportPlaylistTab.allCases, id: \.self) { tab in
                let isSelected = tab == viewModel.tab
                Button {
                    viewModel.select(tab)
                } label: {
                    VStack(spacing: Layout.Spacing.xs) {
                        tab.image.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(viewModel.title(for: tab))
                            .font(Typography.labelMedium)
                            .foregroundStyle(isSelected ? Color.primary1 : Color.text2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Layout.Spacing.s)
                    .background(isSelected ? Color.primary2 : Color.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isSelected ? Color.primary1 : Color.neutralStroke, lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    var fields: some View {
        VStack(spacing: Layout.Spacing.m) {
            FormInputField(
                title: viewModel.nameTitle,
                isRequired: viewModel.isNameRequired,
                icon: Asset.Icon.icImportFieldName,
                placeholder: viewModel.namePlaceholder,
                text: $viewModel.name
            )

            switch viewModel.tab {
            case .playlist, .stream:
                FormInputField(
                    title: viewModel.urlTitle,
                    isRequired: true,
                    icon: Asset.Icon.icImportFieldLink,
                    placeholder: viewModel.urlPlaceholder,
                    text: $viewModel.url,
                    hint: viewModel.urlHint,
                    status: viewModel.urlStatus,
                    keyboardType: .URL
                ) {
                    urlTrailing
                }
            case .file:
                fileField
            }
        }
    }

    @ViewBuilder
    var urlTrailing: some View {
        switch viewModel.urlCheck {
        case .checking:
            ProgressView()
                .tint(Color.text2)
                .frame(width: 24, height: 24)
        case .reachable:
            Asset.Icon.icImportFieldValid.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.accent1)
                .frame(width: 24, height: 24)
        case .idle, .unreachable, .notPlayable:
            EmptyView()
        }
    }

    var fileField: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.s) {
            HStack(spacing: Layout.Spacing.xs) {
                Text(viewModel.fileTitle).foregroundStyle(Color.text2)
                Text("*").foregroundStyle(Color.accent2)
            }
            .font(Typography.labelMedium)

            if let fileName = viewModel.pickedFileName {
                pickedFileRow(fileName)
            } else {
                uploadBox
            }

            Text(viewModel.fileHint)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.text3)
        }
    }

    var uploadBox: some View {
        Button(action: viewModel.didTapChooseFile) {
            VStack(spacing: Layout.Spacing.xs) {
                if viewModel.isUploadingFile {
                    ProgressView()
                        .tint(Color.text2)
                        .frame(width: 24, height: 24)
                } else {
                    Asset.Icon.icImportFolderAdd.image
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(viewModel.isUploadingFile ? viewModel.uploadingTitle : viewModel.selectFileTitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.text1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.Spacing.sm)
            .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(hex: 0xD8D8D8), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isUploadingFile)
    }

    func pickedFileRow(_ fileName: String) -> some View {
        HStack(spacing: Layout.Spacing.s) {
            Asset.Icon.icImportFieldLink.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.text2)
                .frame(width: 24, height: 24)
            Text(fileName)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.text1)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: viewModel.clearPickedFile) {
                Asset.Icon.icFieldClear.image
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(Layout.Spacing.m)
        .frame(height: 56)
        .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.neutralStroke, lineWidth: 1)
        )
        .shadow(.textField)
    }

    var addButton: some View {
        Button(action: viewModel.didTapAdd) {
            HStack(spacing: Layout.Spacing.s) {
                if viewModel.isImporting {
                    ProgressView().tint(Color.text4)
                } else {
                    Asset.Icon.icPlus.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(viewModel.addTitle)
                    .font(Typography.subtitleSmall)
            }
            .foregroundStyle(viewModel.isAddEnabled ? Color.text4 : Color.text3)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(viewModel.isAddEnabled ? Color.primary1 : Color.neutral1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdd || viewModel.isImporting)
    }
}
