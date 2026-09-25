//
//  OnboardView.swift
//  I340_IPTV
//

import SwiftUI

struct OnboardView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        BaseView(background: Color.black) {
            page(for: viewModel.pages[viewModel.currentIndex])
                .id(viewModel.currentIndex)
                .transition(pageTransition)
        }
        .highPriorityGesture(swipeGesture, including: viewModel.isSwipeEnabled ? .all : .none)
    }

    @ViewBuilder
    private func page(for page: Page) -> some View {
        switch page {
        case let .intro(index, item):
            OnboardPageView(item: item, index: index, onNext: viewModel.didTapNext)
        case .fullScreenAd:
            OnboardAdView(onClose: viewModel.didCloseFullScreenAd)
        }
    }

    private var pageTransition: AnyTransition {
        viewModel.isMovingForward
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                viewModel.didSwipe(translation: value.translation.width)
            }
    }
}

#Preview {
    OnboardView()
        .preview()
}
