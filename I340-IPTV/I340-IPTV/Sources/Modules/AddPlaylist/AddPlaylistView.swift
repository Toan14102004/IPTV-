//
//  AddPlaylistView.swift
//  I340_IPTV
//

import SwiftUI
import UniformTypeIdentifiers

/// "Add Channel to Playlist" sheet with the M3U / Xtream / File tabs.
struct AddPlaylistView: View {
    @StateObject private var viewModel: ViewModel
    @FocusState private var focus: Field?
    @State private var contentHeight: CGFloat = 0
    /// Presented from an `.overlay`, so it gets no automatic keyboard avoidance; tracked manually.
    @State private var keyboardHeight: CGFloat = 0

    private enum Field { case name, url, server, username, password }

    init(
        mode: AddPlaylistMode,
        onAddPlaylist: AddXtreamAction?,
        onSubmit: ((PlaylistAddChannelSubmission) -> Void)?,
        dismiss: @escaping (_ animated: Bool, _ completion: (() -> Void)?) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ViewModel(
            mode: mode,
            onAddPlaylist: onAddPlaylist,
            onSubmit: onSubmit,
            dismiss: dismiss
        ))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .onTapGesture { focus = nil }

                sheet(maxHeight: proxy.size.height + proxy.safeAreaInsets.bottom - 8)

                overlayDialog
            }
        }
        .onKeyboardHeightChange { keyboardHeight = $0 }
        .alert(
            "",
            isPresented: Binding(
                get: { messageText != nil },
                set: { if !$0 { viewModel.dismissMessage() } }
            ),
            actions: { Button("ok".localized, role: .cancel) {} },
            message: { Text(messageText ?? "") }
        )
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: playlistFileTypes,
            onCompletion: viewModel.didPickFile
        )
        .onChange(of: viewModel.isFileImporterPresented) { isPresented in
            if !isPresented { viewModel.fileImporterDismissedWithoutPick() }
        }
        .onChange(of: viewModel.name, perform: viewModel.limitName)
    }

    private var messageText: String? {
        if case let .message(text) = viewModel.coordinator.alert { return text }
        return nil
    }

    private var playlistFileTypes: [UTType] {
        let types = ["m3u", "m3u8", "w3u"].compactMap { UTType(filenameExtension: $0) }
        return types.isEmpty ? [.data] : types
    }
}

// MARK: - Sheet

private extension AddPlaylistView {
    func sheet(maxHeight: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Layout.Spacing.m) {
                Capsule()
                    .fill(Asset.Color.handleGray.color)
                    .frame(width: 60, height: 6)
                    .frame(height: 14)

                header

                SegmentedTabs(
                    titles: viewModel.tabTitles,
                    selectedIndex: viewModel.selectedTabIndex,
                    onSelect: { viewModel.selectTab($0) }
                )

                if viewModel.mode == .xtream {
                    avatarPicker
                }

                nameField

                if viewModel.mode == .m3u {
                    playlistURLField
                }

                if viewModel.mode == .xtream {
                    serverField
                    usernameField
                    passwordField
                }

                agreement

                addButton

                Button {
                    focus = nil
                    viewModel.didTapHowToUse()
                } label: {
                    Text("playlist_add_how_to_use".localized)
                        .font(FontFamily.Poppins.regular.font(size: 14))
                        .foregroundColor(.brand)
                        .underline()
                        .frame(height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Layout.Spacing.l)
            .padding(.top, Layout.Spacing.s)
            // Extra room while the keyboard is up so the last fields can scroll clear of it.
            .padding(.bottom, Layout.Spacing.xl + keyboardHeight)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { contentHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { contentHeight = $0 }
                }
            )
        }
        // Sized to its content, scrolling only when the content is taller than the screen.
        .frame(height: contentHeight > 0 ? min(contentHeight, maxHeight) : maxHeight)
        .animation(.easeInOut(duration: 0.24), value: contentHeight)
        .background(
            TopRoundedShape(radius: 32)
                .fill(Asset.Color.screenBackground.color)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    var header: some View {
        HStack(spacing: 18) {
            Button(action: viewModel.didTapBack) {
                Asset.Icon.icArrowLeft.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(viewModel.title)
                .font(FontFamily.Poppins.medium.font(size: 20))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 32)
    }

    var avatarPicker: some View {
        VStack(alignment: .leading, spacing: Layout.Spacing.s) {
            Text("playlist_add_select_avatar".localized)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .foregroundColor(Asset.Color.textGray.color)

            HStack(spacing: Layout.Spacing.sm) {
                ForEach(ViewModel.avatars, id: \.name) { avatar in
                    let isSelected = viewModel.selectedAvatar == avatar.name
                    avatar.image.image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.CornerRadius.medium)
                                .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture { viewModel.selectAvatar(avatar.name) }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Fields

private extension AddPlaylistView {
    func fieldGroup<Field: View>(
        _ title: String,
        @ViewBuilder _ field: () -> Field
    ) -> some View {
        VStack(spacing: Layout.Spacing.s) {
            FormFieldTitle(title: title, isRequired: true)
            field()
        }
    }

    func prompt(_ key: String) -> Text {
        Text(key.localized).foregroundColor(Asset.Color.textGray.color)
    }

    var nameField: some View {
        fieldGroup("playlist_add_name_label".localized) {
            TextField("", text: $viewModel.name, prompt: prompt("playlist_add_name_placeholder"))
                .focused($focus, equals: .name)
                .submitLabel(viewModel.mode == .file ? .done : .next)
                .onSubmit { focus = nextField(after: .name) }
                .formFieldBox()
        }
    }

    var playlistURLField: some View {
        fieldGroup("playlist_add_playlist_url_label".localized) {
            TextField("", text: $viewModel.playlistURL, prompt: prompt("playlist_add_playlist_url_placeholder"))
                .keyboardType(.URL)
                .focused($focus, equals: .url)
                .submitLabel(.done)
                .onSubmit { focus = nil }
                .formFieldBox()
        }
    }

    var serverField: some View {
        fieldGroup("playlist_add_server_url_label".localized) {
            TextField("", text: $viewModel.serverURL, prompt: prompt("playlist_add_server_url_placeholder"))
                .keyboardType(.URL)
                .focused($focus, equals: .server)
                .submitLabel(.next)
                .onSubmit { focus = .username }
                .formFieldBox()
        }
    }

    var usernameField: some View {
        fieldGroup("playlist_add_username_label".localized) {
            TextField("", text: $viewModel.username, prompt: prompt("playlist_add_username_placeholder"))
                .focused($focus, equals: .username)
                .submitLabel(.next)
                .onSubmit { focus = .password }
                .formFieldBox()
        }
    }

    var passwordField: some View {
        fieldGroup("playlist_add_password_label".localized) {
            HStack(spacing: 0) {
                Group {
                    if viewModel.isPasswordVisible {
                        TextField("", text: $viewModel.password, prompt: prompt("playlist_add_password_placeholder"))
                    } else {
                        SecureField("", text: $viewModel.password, prompt: prompt("playlist_add_password_placeholder"))
                    }
                }
                .focused($focus, equals: .password)
                .submitLabel(.done)
                .onSubmit { focus = nil }

                Button {
                    viewModel.isPasswordVisible.toggle()
                } label: {
                    (viewModel.isPasswordVisible ? Asset.Image.Movies.icPasswordXtreamOpen : Asset.Image.Movies.icPasswordXtream)
                        .image
                        .renderingMode(.template)
                        .foregroundColor(Asset.Color.textGray.color)
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .formFieldBox()
        }
    }

    private func nextField(after field: Field) -> Field? {
        switch (viewModel.mode, field) {
        case (.m3u, .name): .url
        case (.xtream, .name): .server
        default: nil
        }
    }
}

// MARK: - Agreement & button

private extension AddPlaylistView {
    var agreement: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.toggleAgreement) {
                (viewModel.isAgreementSelected ? Asset.Image.Movies.icAgreementSelect : Asset.Image.Movies.icAgreementUnselect)
                    .image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)

            Text(agreementText)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    if url.scheme == "license" { viewModel.openLicense() }
                    return .handled
                })
                .onTapGesture(perform: viewModel.toggleAgreement)
        }
    }

    /// "By tapping Add, you agree to our " + a tappable red "License Agreement".
    var agreementText: AttributedString {
        var prefix = AttributedString("playlist_add_agreement_prefix".localized)
        prefix.foregroundColor = Asset.Color.textGray.color

        var license = AttributedString(viewModel.licenseText)
        license.foregroundColor = .brand
        license.link = URL(string: "license://terms")

        return prefix + license
    }

    var addButton: some View {
        Button {
            focus = nil
            viewModel.didTapAdd()
        } label: {
            HStack(spacing: Layout.Spacing.s) {
                Image(systemName: "plus")
                Text(viewModel.primaryTitle)
                    .font(FontFamily.Poppins.medium.font(size: viewModel.primaryFontSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.gradient(colors: gradientColors, cornerRadius: 25))
        .opacity(viewModel.isSubmitting ? 0.65 : 1)
        .disabled(viewModel.isSubmitting)
    }

    var gradientColors: [Color] {
        viewModel.mode == .file
            ? [Asset.Color.brandMaroonDark.color, Asset.Color.brandMaroon.color, Asset.Color.brandMaroonDark.color]
            : [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color, Asset.Color.brandRedDark.color]
    }
}

// MARK: - Dialogs

private extension AddPlaylistView {
    @ViewBuilder
    var overlayDialog: some View {
        switch viewModel.coordinator.alert {
        case .xtreamLoading:
            LoadingDialogView(
                title: "xtream_loading_title".localized,
                message: "xtream_loading_message".localized,
                closeTitle: "playlist_loading_close".localized,
                onClose: viewModel.cancelXtreamImport,
                background: Asset.Color.dialogBackground.color,
                dimOpacity: 0.42
            )
        case .xtreamFailed:
            ImportFailedDialogView(
                title: "xtream_import_failed_title".localized,
                message: "xtream_import_failed_message".localized,
                closeTitle: "playlist_loading_close".localized,
                onClose: viewModel.closeFailedDialog
            )
        case .message, .none:
            EmptyView()
        }
    }
}
