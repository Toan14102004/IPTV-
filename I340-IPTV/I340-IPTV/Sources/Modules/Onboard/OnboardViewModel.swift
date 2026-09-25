//
//  OnboardViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import SwiftUI

extension OnboardView {
    enum Page: Identifiable {
        case intro(index: Int, item: OnboardItem)
        /// Full-screen native ad shown between the second and the third intro page.
        case fullScreenAd

        var id: String {
            switch self {
            case let .intro(index, _): "intro-\(index)"
            case .fullScreenAd: "full-screen-ad"
            }
        }
    }

    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var currentIndex = 0
        /// Direction of the last move, used to slide pages the right way.
        @Published private(set) var isMovingForward = true

        let pages: [Page]

        private let appState: Store<AppState>
        private let isFullScreenAdEnabled = RemoteKonfig.shared.isShowNativeAdsFullScreenIntro

        /// Swiping is only allowed on the third position (the full-screen ad); otherwise the
        /// Next button drives the flow.
        var isSwipeEnabled: Bool { isFullScreenAdEnabled && currentIndex == 2 }

        init(appState: Store<AppState> = AppEnvironment.shared.container.appState) {
            self.appState = appState

            var pages: [Page] = []
            for (index, item) in Self.introItems.enumerated() {
                if index == 2, isFullScreenAdEnabled, AdsManager.shared.isFullScreenAdAvailable() {
                    pages.append(.fullScreenAd)
                }
                pages.append(.intro(index: index, item: item))
            }
            self.pages = pages
        }

        // MARK: - Actions

        func didTapNext() {
            let next = currentIndex + 1
            if next < pages.count {
                move(to: next)
            } else {
                finish()
            }
        }

        func didCloseFullScreenAd() {
            move(to: currentIndex + 1)
        }

        func didSwipe(translation: CGFloat) {
            guard isSwipeEnabled else { return }
            move(to: translation < 0 ? currentIndex + 1 : currentIndex - 1)
        }

        // MARK: - Private

        private func move(to index: Int) {
            guard pages.indices.contains(index) else { return }
            isMovingForward = index > currentIndex
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex = index
            }
        }

        private func finish() {
            AdsManager.shared.updateIsAfterFlow2F(true)
            appState[\.route] = .main
        }

        private static var introItems: [OnboardItem] {
            [
                OnboardItem(
                    title: "onboard_title_first".localized,
                    subTitle: "onboard_title_first_message".localized,
                    image: "img_onboard_first",
                    pageControlImage: "ic_pagecontrol_first"
                ),
                OnboardItem(
                    title: "onboard_title_second".localized,
                    subTitle: "onboard_title_second_message".localized,
                    image: "img_onboard_second",
                    pageControlImage: "ic_pagecontrol_second",
                    isShowBottomNextButton: true
                ),
                OnboardItem(
                    title: "onboard_title_third".localized,
                    subTitle: "onboard_title_third_message".localized,
                    image: "img_onboard_third",
                    pageControlImage: "ic_pagecontrol_third"
                )
            ]
        }
    }
}
