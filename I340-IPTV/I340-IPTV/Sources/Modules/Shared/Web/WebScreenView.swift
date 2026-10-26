//
//  WebScreenView.swift
//  I340_IPTV
//

import SwiftUI
import WebKit

struct WebScreenView: View {
    @StateObject private var viewModel: ViewModel

    init(urlString: String, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(urlString: urlString, onClose: onClose))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WebViewRepresentable(
                urlString: viewModel.urlString,
                onStart: viewModel.didStartLoading,
                onFinish: viewModel.didFinishLoading,
                onFail: viewModel.didFailLoading
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button(action: viewModel.didTapClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, Layout.Spacing.s)
            .padding(.trailing, Layout.Spacing.m)
        }
        .background(Color.white.ignoresSafeArea())
        .alert(
            viewModel.errorTitle,
            isPresented: Binding(
                get: { viewModel.coordinator.alert != nil },
                set: { if !$0 { viewModel.coordinator.alert = nil } }
            )
        ) {
            Button("ok".localized, action: viewModel.didTapClose)
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let urlString: String
    let onStart: () -> Void
    let onFinish: () -> Void
    let onFail: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onStart()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onFinish()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onFail()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onFail()
        }
    }
}
