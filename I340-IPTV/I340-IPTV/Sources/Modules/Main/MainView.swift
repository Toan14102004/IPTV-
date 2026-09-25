//
//  MainView.swift
//  I340_IPTV
//

import SwiftUI

/// Home: Playlist and Xtream tabs with the bottom tab bar.
struct MainView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        BaseView(background: Asset.Color.screenBackground.color) {
            VStack(spacing: 0) {
                tabContents
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                MainTabBar(
                    selectedTab: viewModel.selectedTab,
                    playlistTitle: viewModel.playlistTitle,
                    xtreamTitle: viewModel.xtreamTitle,
                    onSelect: viewModel.select,
                    onAdd: viewModel.didTapAdd
                )
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .overlay { overlayContent }
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case let .reinstallRequired(appID):
                CustomAlertView(
                    title: "Installation Required",
                    description: "To continue using our services please install the latest version of our app",
                    cancelActionTitle: nil,
                    primaryActionTitle: "Install now",
                    primaryActionTitleColor: .white,
                    primaryAction: { viewModel.openStore(for: appID) }
                )
            }
        } customize: { params in
            params.centerPopup().closeOnTap(false).closeOnTapOutside(false)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if let overlay = viewModel.coordinator.overlay {
            switch overlay {
            case .addMenu:
                addMenuSheet
            case .addStream:
                addStreamSheet
            case let .addPlaylist(mode, owner):
                addPlaylistForm(mode: mode, owner: owner)
            }
        }
    }

    private var addMenuSheet: some View {
        BottomSheetContainer(onDismiss: closeSheet) { close in
            AddPlaylistMenuView(
                close: close,
                onSelect: { viewModel.didSelectAddOption($0) },
                onHowToUse: { AppNavigator.present(.guide) }
            )
        }
    }

    private var addStreamSheet: some View {
        BottomSheetContainer(onDismiss: closeSheet) { close in
            AddStreamSheetView(
                close: close,
                onSubmit: { viewModel.playlistViewModel.handleAddSubmission($0) },
                onHowToUse: { AppNavigator.present(.guide) }
            )
        }
    }

    private func addPlaylistForm(mode: AddPlaylistMode, owner: Tab) -> some View {
        var onSubmit: ((PlaylistAddChannelSubmission) -> Void)?
        if owner == .playlist {
            let playlistViewModel = viewModel.playlistViewModel
            onSubmit = { submission in playlistViewModel.handleAddSubmission(submission) }
        }
        return AddPlaylistView(
            mode: mode,
            onAddPlaylist: viewModel.addProfileAction(for: owner),
            onSubmit: onSubmit,
            dismiss: { animated, completion in
                viewModel.closeOverlay(animated: animated, completion: completion)
            }
        )
        .transition(.move(edge: .bottom))
    }

    private func closeSheet(_ completion: (() -> Void)?) {
        viewModel.closeOverlay(animated: false, completion: completion)
    }

    /// Both tabs stay alive once opened; the inactive one is only made invisible, as before.
    private var tabContents: some View {
        ZStack {
            if viewModel.visitedTabs.contains(.playlist) {
                tabVisibility(.playlist) {
                    PlaylistView(viewModel: viewModel.playlistViewModel)
                }
            }
            if viewModel.visitedTabs.contains(.xtream) {
                tabVisibility(.xtream) {
                    XtreamView(viewModel: viewModel.xtreamViewModel)
                }
            }
        }
    }

    private func tabVisibility<Content: View>(_ tab: Tab, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
    }
}

#Preview {
    MainView()
        .preview()
}
