//
//  RootView.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

struct RootView: View {
    @EnvironmentObject var loadingService: LoadingService
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            FlowStack($viewModel.path, withNavigation: true) {
                content
                    .animation(.easeInOut(duration: 0.3), value: viewModel.route)
                    .navigationBarHidden(true)
                    .modifier(NavigatorModifier())
                    .flowDestination(for: Coordinator.Navigation.self) { item in
                        destination(for: item)
                            .hidesNavigationBar()
                    }
                    .flowDestination(for: Coordinator.FullScreen.self) { item in
                        fullScreen(for: item)
                    }
            }

            if loadingService.isLoading {
                VStack {
                    ActivityIndicatorView(
                        isVisible: $loadingService.isLoading,
                        type: loadingService.indicatorType
                    )
                    .foregroundColor(loadingService.indicatorColor)
                    .frame(width: Layout.Spacing.xxl, height: Layout.Spacing.xxl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(Layout.Opacity.medium))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.route {
        case let .splash(isFromLanguageSetting):
            SplashView(isFromLanguageSetting: isFromLanguageSetting)
        case .language:
            LanguageView(context: .onboarding)
        case .onboard:
            OnboardView()
        case .main:
            MainView()
        }
    }

    @ViewBuilder
    private func destination(for item: Coordinator.Navigation) -> some View {
        switch item {
        case .settings:
            SettingsView(onBack: AppNavigator.back)
        case let .playlistChannels(playlist):
            PlaylistChannelView(playlist: playlist, onBack: AppNavigator.back)
        case .playlistFavorites:
            PlaylistFavoriteView(onBack: AppNavigator.back)
        case let .playlistPlayer(playlist, channel):
            PlaylistPlayerView(playlist: playlist, channel: channel, onBack: AppNavigator.back)
        case let .xtreamFavorites(playlist):
            XtreamFavoriteView(playlist: playlist, onBack: AppNavigator.back)
        case let .xtreamDetail(channel, related, playlistID):
            XtreamDetailView(channel: channel, related: related.channels, playlistID: playlistID, onBack: AppNavigator.back)
        }
    }

    @ViewBuilder
    private func fullScreen(for item: Coordinator.FullScreen) -> some View {
        switch item {
        case .guide:
            GuideView(onBack: AppNavigator.back)
        case .paywall:
            PaywallView { isPurchased in
                AppNavigator.back()
                // Tell the watch-limit logic once the paywall is gone.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    PaywallCenter.shared.finish(isPurchased: isPurchased)
                }
            }
        case .language:
            LanguageView(context: .settings(onClose: AppNavigator.back))
        case let .web(url):
            WebScreenView(urlString: url, onClose: AppNavigator.back)
        }
    }
}
