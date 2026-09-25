//
//  XtreamView.swift
//  I340_IPTV
//

import SwiftUI

/// Xtream tab: intro and saved profiles, or the content of the opened profile.
struct XtreamView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            Asset.Color.screenBackground.color.ignoresSafeArea()

            if let content = viewModel.content {
                XtreamContentView(viewModel: content)
            } else {
                profileList
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .trackScreen("Xtream")
        .actionMenu(
            activeID: viewModel.coordinator.actionMenuID,
            items: menuItems,
            onDismiss: viewModel.closeMenu
        )
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
                title: "playlist_rename_title".localized(fallback: "Rename"),
                placeholder: "playlist_rename_placeholder".localized(fallback: "Playlist name"),
                continueTitle: "playlist_rename_continue".localized(fallback: "Continue"),
                emptyNameMessage: "playlist_rename_empty_error".localized(fallback: "The name cannot be left blank."),
                currentName: profile.name,
                onClose: { viewModel.coordinator.rename = nil },
                onContinue: { viewModel.rename(profile, to: $0) }
            )
        } customize: { params in
            params.bottomPopup().useKeyboardSafeArea(true).backgroundColor(.dialogDim)
        }
    }

    private var menuItems: [ActionMenuItem] {
        guard let id = viewModel.coordinator.actionMenuID,
              let profile = viewModel.profiles.first(where: { $0.id == id }) else { return [] }
        return viewModel.menuItems(for: profile)
    }
}

// MARK: - Profile list

private extension XtreamView {
    var profileList: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, Layout.Spacing.m)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Asset.Icon.imgXtreamHero.image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 376)
                        .frame(height: 244)
                        .padding(.top, Layout.Spacing.s)

                    Text("main_xtream_description".localized)
                        .font(FontFamily.Poppins.regular.font(size: 14))
                        .foregroundColor(Asset.Color.textTertiary.color)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Layout.Spacing.xxl)
                        .padding(.top, Layout.Spacing.l)

                    categories
                        .padding(.top, Layout.Spacing.l)

                    addProfileButton
                        .padding(.top, Layout.Spacing.l)

                    profilesColumn
                        .padding(.top, Layout.Spacing.l)
                        .padding(.bottom, Layout.Spacing.m)
                }
                .padding(.horizontal, Layout.Spacing.m)
            }
        }
    }

    var header: some View {
        HStack(spacing: Layout.Spacing.sm) {
            Text(viewModel.screenTitle)
                .font(FontFamily.Poppins.medium.font(size: 24))
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
    }

    var categories: some View {
        HStack(spacing: 10) {
            category(Asset.Icon.icXtreamLiveTv, "main_xtream_live_tv")
            divider
            category(Asset.Icon.icXtreamMovies, "main_xtream_movies")
            divider
            category(Asset.Icon.icXtreamSeries, "main_xtream_series")
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 1, height: 24)
    }

    func category(_ icon: ImageAsset, _ titleKey: String) -> some View {
        HStack(spacing: Layout.Spacing.xs) {
            icon.image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(titleKey.localized)
                .font(FontFamily.Poppins.medium.font(size: 10))
                .foregroundColor(Asset.Color.textTertiary.color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    var addProfileButton: some View {
        Button(action: viewModel.didTapAddButton) {
            HStack(spacing: Layout.Spacing.s) {
                Asset.Icon.icMainTabAdd.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("main_add_profile".localized)
                    .font(FontFamily.Poppins.medium.font(size: 16))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(minWidth: 185)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [Asset.Color.brandRedDark.color, Asset.Color.brandRed.color, Asset.Color.brandRedDark.color],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var profilesColumn: some View {
        VStack(spacing: Layout.Spacing.sm) {
            ForEach(viewModel.profiles) { profile in
                XtreamProfileRow(
                    profile: profile,
                    onTap: { viewModel.open(profile) },
                    onMore: { viewModel.showMenu(for: profile) }
                )
            }
        }
    }
}
