//
//  XtreamView.swift
//  I340_IPTV
//

import SwiftUI

struct XtreamView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            Color.background1.ignoresSafeArea()

            if let content = viewModel.content {
                XtreamContentView(viewModel: content)
            } else {
                profileList
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("Xtream")
        .toast(message: $viewModel.toast)
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case let .disclaimer(profile):
                XtreamDisclaimerDialogView(
                    onCancel: viewModel.dismissAlert,
                    onContinue: { viewModel.continueWithDisclaimer(for: profile) }
                )
            case let .deleteProfile(profile):
                ConfirmDialogView(
                    title: "playlist_delete_confirm_title".localized(fallback: "Delete?"),
                    message: "playlist_delete_confirm_message".localized(fallback: "Are you sure you want to delete this item?"),
                    noTitle: "playlist_delete_no".localized(fallback: "No"),
                    yesTitle: "playlist_delete_yes".localized(fallback: "Yes"),
                    onNo: viewModel.dismissAlert,
                    onYes: { viewModel.delete(profile) }
                )
            }
        } customize: { params in
            params.centerPopup().backgroundColor(.dialogDim)
        }
        .popup(item: $viewModel.coordinator.rename) { profile in
            RenameSheetView(
                title: "playlist_rename_playlist_title".localized(fallback: "Rename Playlist"),
                placeholder: "playlist_rename_placeholder".localized(fallback: "Playlist name"),
                continueTitle: "playlist_rename_save".localized(fallback: "Save"),
                emptyNameMessage: "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank."),
                currentName: profile.name,
                onClose: { viewModel.coordinator.rename = nil },
                onContinue: { viewModel.rename(profile, to: $0) }
            )
        } customize: { params in
            params.centerPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDimLight)
        }
    }
}

// MARK: - Profile list

private extension XtreamView {
    var profileList: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: viewModel.screenTitle,
                onFavorite: viewModel.didTapFavorites,
                onHelp: viewModel.didTapHelp,
                onPremium: viewModel.premiumAction
            )

            if viewModel.profiles.isEmpty {
                emptyState
            } else {
                library
            }
        }
    }

    var nativeAd: some View {
        NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 200) {
            MediumNativeAdView(frame: .zero)
        }
    }

    var emptyState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                nativeAd

                VStack(spacing: Layout.Spacing.l) {
                    Asset.Image.imgXtreamEmptyTitle.image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 312)

                    VStack(spacing: Layout.Spacing.xs) {
                        Text("playlist_empty_title".localized(fallback: "You don't have any playlists"))
                            .font(Typography.subtitleLarge)
                            .foregroundStyle(Color.text1)
                        Text("playlist_empty_message".localized(
                            fallback: "Xtream Codes is the most popular and widely used platform for IPTV streaming."
                        ))
                            .font(Typography.bodySmall)
                            .foregroundStyle(Color.text2)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Layout.Spacing.m)
                }
                .padding(.top, 66)

                Button(action: viewModel.didTapAddButton) {
                    HStack(spacing: Layout.Spacing.s) {
                        Asset.Icon.icPlus.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("playlist_add_playlist".localized(fallback: "Add Playlist"))
                            .font(Typography.subtitleSmall)
                    }
                    .foregroundStyle(Color.text4)
                    .padding(Layout.Spacing.sm)
                    .frame(height: 48)
                    .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, Layout.Spacing.l)
            }
        }
    }

    var library: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Layout.Spacing.sm) {
                PlaylistSearchField(text: $viewModel.searchText)

                if viewModel.filteredProfiles.isEmpty {
                    Text("playlist_search_no_result".localized(fallback: "No playlists found"))
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.text2)
                        .padding(.top, Layout.Spacing.xl)
                }

                ForEach(Array(viewModel.filteredProfiles.enumerated()), id: \.element.id) { index, profile in
                    XtreamProfileRow(
                        profile: profile,
                        isFavorite: viewModel.isFavorite(profile),
                        onTap: { viewModel.open(profile) },
                        onFavorite: { viewModel.toggleFavorite(profile) },
                        onDelete: { viewModel.coordinator.alert = .deleteProfile(profile) }
                    )

                    if index == 1 {
                        nativeAd
                    }
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.top, Layout.Spacing.xs)
            .padding(.bottom, Layout.Spacing.l)
        }
        .scrollDismissesKeyboardIfAvailable()
    }
}
