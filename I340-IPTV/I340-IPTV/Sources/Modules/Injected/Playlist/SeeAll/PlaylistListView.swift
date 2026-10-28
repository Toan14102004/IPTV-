//
//  PlaylistListView.swift
//  I340_IPTV
//

import SwiftUI

struct PlaylistListView: View {
    @StateObject private var viewModel: ViewModel

    init(section: PlaylistSection, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(section: section, onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: viewModel.title,
                    onBack: viewModel.didTapBack,
                    onPremium: viewModel.premiumAction
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Layout.Spacing.m) {
                        PlaylistSearchField(text: $viewModel.searchText)

                        if viewModel.items.isEmpty {
                            Text(viewModel.emptyTitle)
                                .font(Typography.bodySmall)
                                .foregroundStyle(Color.text2)
                                .padding(.top, Layout.Spacing.xl)
                        }

                        switch viewModel.section {
                        case .playlists: playlistList
                        case .videos: videoGrid
                        }
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                    .padding(.top, Layout.Spacing.xs)
                    .padding(.bottom, Layout.Spacing.l)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.deleting) { playlist in
            PlaylistDeleteDialog(onNo: viewModel.cancelDelete, onYes: { viewModel.delete(playlist) })
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }

    private var playlistList: some View {
        LazyVStack(spacing: Layout.Spacing.sm) {
            ForEach(viewModel.items, id: \.id) { playlist in
                PlaylistCard(
                    playlist: playlist,
                    isFavorite: viewModel.isFavorite(playlist),
                    onTap: { viewModel.open(playlist) },
                    onFavorite: { viewModel.toggleFavorite(playlist) },
                    onDelete: { viewModel.deleting = playlist }
                )
            }
        }
    }

    private var videoGrid: some View {
        LazyVGrid(columns: PlaylistGrid.columns, spacing: Layout.Spacing.sm) {
            ForEach(viewModel.items, id: \.id) { playlist in
                VideoCard(
                    playlist: playlist,
                    isFavorite: viewModel.isFavorite(playlist),
                    onTap: { viewModel.open(playlist) },
                    onFavorite: { viewModel.toggleFavorite(playlist) },
                    onDelete: { viewModel.deleting = playlist }
                )
                .onAppear { viewModel.refreshDurationIfNeeded(playlist) }
            }
            AddPlaylistDashedCard(action: viewModel.didTapAddFile)
        }
    }
}
