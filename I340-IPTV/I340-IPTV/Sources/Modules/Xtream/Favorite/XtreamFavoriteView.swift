//
//  XtreamFavoriteView.swift
//  I340_IPTV
//

import SwiftUI

struct XtreamFavoriteView: View {
    @StateObject private var viewModel: ViewModel
    @FocusState private var isSearchFocused: Bool

    init(playlist: IPTVPlaylist?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(playlist: playlist, onBack: onBack))
    }

    var body: some View {
        ZStack {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                searchRow
                    .padding(.top, Layout.Spacing.m)

                content
                    .padding(.top, 13)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.isSubscribed {
                    NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                        MediumNativeAdView(frame: .zero)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("XtreamFavorite")
        .popup(item: $viewModel.coordinator.alert) { _ in
            ConfirmDialogView(
                title: "playlist_delete_confirm_title".localized,
                message: "xtream_favorite_clear_confirm_message".localized,
                noTitle: "playlist_delete_no".localized,
                yesTitle: "playlist_delete_yes".localized,
                onNo: viewModel.dismissAlert,
                onYes: viewModel.confirmClearAll
            )
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
    }
}

// MARK: - Sections

private extension XtreamFavoriteView {
    var header: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Text(viewModel.screenTitle)
                .font(FontFamily.Poppins.medium.font(size: 26))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            HeaderActionButtons(
                isSubscribed: viewModel.isSubscribed,
                onPremium: viewModel.didTapPremium,
                onSettings: viewModel.didTapSettings,
                onHelp: viewModel.didTapHelp
            )
        }
        .padding(.horizontal, Layout.Spacing.m)
        .padding(.top, Layout.Spacing.m)
    }

    var searchRow: some View {
        HStack(spacing: Layout.Spacing.sm) {
            BackButton(action: viewModel.didTapBack)
                .frame(width: 24, height: 24)

            HStack(spacing: 10) {
                XtreamAvatarImage(name: viewModel.avatarName)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())

                TextField(
                    "",
                    text: $viewModel.keyword,
                    prompt: Text(viewModel.searchPlaceholder).foregroundColor(Asset.Color.textGray.color)
                )
                .font(FontFamily.Poppins.regular.font(size: 17))
                .foregroundColor(.white)
                .tint(Asset.Color.brandRed.color)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .focused($isSearchFocused)

                Image(systemName: "magnifyingglass")
                    .foregroundColor(Asset.Color.textGray.color)
                    .frame(width: 26, height: 26)
            }
            .padding(.horizontal, 7)
            .frame(height: 58)
            .background(Asset.Color.fieldBackground.color)
            .clipShape(Capsule())

            Button(action: viewModel.didTapClearAll) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.favorites.isEmpty)
            .opacity(viewModel.favorites.isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, Layout.Spacing.m)
    }

    @ViewBuilder
    var content: some View {
        let items = viewModel.filteredFavorites
        if items.isEmpty {
            Text(viewModel.emptyText)
                .font(FontFamily.Poppins.medium.font(size: 16))
                .foregroundColor(Asset.Color.textGray.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Layout.Spacing.m) {
                    ForEach(items) { channel in
                        ChannelRow(
                            channel: channel,
                            isFavorite: true,
                            onTap: { viewModel.open(channel) },
                            onFavorite: { viewModel.remove(channel) }
                        )
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.bottom, Layout.Spacing.s)
            }
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
        }
    }
}
