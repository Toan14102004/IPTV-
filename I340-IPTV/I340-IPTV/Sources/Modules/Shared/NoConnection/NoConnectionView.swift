//
//  NoConnectionView.swift
//  I340_IPTV
//

import SwiftUI

/// Full-screen "no internet" overlay shown by `NetworkOverlayManager` while the device is offline.
struct NoConnectionView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Asset.Icon.iconNoConnection.image
                .resizable()
                .scaledToFit()
                .frame(width: 202, height: 184)

            Text("whoops".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.top, 40)

            Text("no_internet_message".localized)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.top, Layout.Spacing.sm)
                .padding(.horizontal, Layout.Spacing.xl)

            HStack(spacing: Layout.Spacing.sm) {
                Button(action: viewModel.didTapTryAgain) {
                    Text("try_again".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(.link))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.CornerRadius.medium))
                }
                Button(action: viewModel.didTapGoToSettings) {
                    Text("go_to_settings".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.link))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.CornerRadius.medium)
                                .stroke(Color(red: 0.82, green: 0.83, blue: 0.86), lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(.top, Layout.Spacing.l)
            .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(
            "no_connection_title".localized,
            isPresented: Binding(
                get: { viewModel.coordinator.alert != nil },
                set: { if !$0 { viewModel.coordinator.alert = nil } }
            )
        ) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("no_connection_message".localized)
        }
    }
}

#Preview {
    NoConnectionView()
}
