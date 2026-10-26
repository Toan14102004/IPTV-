//
//  PlaylistChannelView.swift
//  I340_IPTV
//

import SwiftUI

struct PlaylistChannelView: View {
    @StateObject private var viewModel: ViewModel

    init(playlist: IPTVPlaylist, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(playlist: playlist, onBack: onBack))
    }

    var body: some View {
        BaseView(background: Color.background1) {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: viewModel.playlist.name,
                    onBack: viewModel.didTapBack,
                    onPremium: viewModel.premiumAction
                )

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.isSubscribed {
                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("PlaylistChannel")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case let .deleteChannel(channel):
                DeleteDialogView(onCancel: viewModel.dismissAlert, onDelete: { viewModel.delete(channel) })
            }
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDimLight)
        }
        .popup(item: $viewModel.coordinator.rename) { channel in
            RenameSheetView(
                title: "playlist_rename_channel_title".localized(fallback: "Rename Channel"),
                placeholder: "playlist_rename_placeholder".localized(fallback: "Playlist name"),
                continueTitle: "playlist_rename_save".localized(fallback: "Save"),
                emptyNameMessage: "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank."),
                currentName: channel.title.isEmpty ? channel.url : channel.title,
                onClose: { viewModel.coordinator.rename = nil },
                onContinue: { viewModel.rename(channel, to: $0) }
            )
        } customize: { params in
            params.centerPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDimLight)
        }
    }

    @ViewBuilder
    private var content: some View {
        let channels = viewModel.playlist.channels
        if channels.isEmpty {
            Text(viewModel.emptyMessage)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.Spacing.s) {
                    Text(viewModel.channelCountText)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.text2)
                        .padding(.horizontal, Layout.Spacing.m)

                    LazyVStack(spacing: Layout.Spacing.s) {
                        ForEach(channels) { channel in
                            PlaylistChannelCard(channel: channel, onTap: { viewModel.open(channel) })
                                .contextMenu {
                                    Button { viewModel.coordinator.rename = channel } label: {
                                        Text("playlist_action_rename".localized(fallback: "Rename"))
                                    }
                                    Button(role: .destructive) { viewModel.coordinator.alert = .deleteChannel(channel) } label: {
                                        Text("playlist_action_delete".localized(fallback: "Delete"))
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                }
                .padding(.bottom, Layout.Spacing.s)
            }
        }
    }
}
