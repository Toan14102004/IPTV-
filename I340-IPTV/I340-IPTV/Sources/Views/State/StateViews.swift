//
//  StateViews.swift
//  I340_IPTV
//

import SwiftUI

/// Centered spinner with an optional text.
struct LoadingStateView: View {
    var message: String?

    var body: some View {
        VStack(spacing: Layout.Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.3)
                .tint(.white)
            if let message {
                Text(message)
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(Asset.Color.textGray.color)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// "Nothing here yet": an icon, a title, a hint and an optional action.
struct EmptyStateView: View {
    var systemImage = "tray"
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        StateLayout(systemImage: systemImage, title: title, message: message, actionTitle: actionTitle, action: action)
    }
}

/// A failure with a "Try again" button (when the error can be retried).
struct ErrorStateView: View {
    let error: AppError
    var retry: (() -> Void)?

    init(error: Error, retry: (() -> Void)? = nil) {
        self.error = AppError(error)
        self.retry = retry
    }

    var body: some View {
        StateLayout(
            systemImage: "exclamationmark.triangle",
            title: "error".localized,
            message: error.message,
            actionTitle: error.isRetryable && retry != nil ? "try_again".localized : nil,
            action: retry
        )
    }
}

/// Renders a `Loadable` as loading, error, empty or content.
///
///     LoadableStateView(state: viewModel.items, isEmpty: { $0.isEmpty }, retry: viewModel.load) { items in
///         List(items) { … }
///     }
struct LoadableStateView<Value, Content: View, Empty: View>: View {
    let state: Loadable<Value>
    let isEmpty: (Value) -> Bool
    var retry: (() -> Void)?
    @ViewBuilder let empty: () -> Empty
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .notRequested:
            Color.clear
        case let .isLoading(last, _):
            if let last, !isEmpty(last) {
                content(last)
            } else {
                LoadingStateView()
            }
        case let .loaded(value):
            if isEmpty(value) { empty() } else { content(value) }
        case let .failed(error):
            ErrorStateView(error: error, retry: retry)
        }
    }
}

extension LoadableStateView where Empty == EmptyStateView {
    init(
        state: Loadable<Value>,
        isEmpty: @escaping (Value) -> Bool,
        retry: (() -> Void)? = nil,
        emptyTitle: String = "No data",
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(state: state, isEmpty: isEmpty, retry: retry, empty: { EmptyStateView(title: emptyTitle) }, content: content)
    }
}

// MARK: - Shared layout

private struct StateLayout: View {
    let systemImage: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Layout.Spacing.s) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundColor(Asset.Color.textTertiary.color)
                .padding(.bottom, Layout.Spacing.s)

            Text(title)
                .font(FontFamily.Poppins.medium.font(size: 18))
                .foregroundColor(.white)

            if let message {
                Text(message)
                    .font(FontFamily.Poppins.regular.font(size: 14))
                    .foregroundColor(Asset.Color.textGray.color)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(FontFamily.Poppins.medium.font(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, Layout.Spacing.l)
                        .frame(height: 40)
                        .background(Asset.Color.brandRed.color)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, Layout.Spacing.s)
            }
        }
        .padding(.horizontal, Layout.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Empty") {
    EmptyStateView(title: "No playlists yet", message: "Tap the Add button to create one.")
        .background(Color.black)
}

#Preview("Error") {
    ErrorStateView(error: NetworkError.noConnection, retry: {})
        .background(Color.black)
}
