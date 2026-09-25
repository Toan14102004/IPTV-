//
//  AddStreamSheetView.swift
//  I340_IPTV
//

import SwiftUI

/// "Add Stream" bottom sheet: an optional name and the URL of a single stream.
struct AddStreamSheetView: View {
    let close: (_ completion: (() -> Void)?) -> Void
    let onSubmit: (PlaylistAddChannelSubmission) -> Void
    let onHowToUse: () -> Void

    @State private var streamName = ""
    @State private var streamURL = ""
    @State private var isAgreementSelected = false
    @State private var toastMessage: String?
    @FocusState private var focus: Field?

    private enum Field { case name, url }

    var body: some View {
        GeometryReader { proxy in
            let maxHeight = max(420, proxy.size.height - 20)

            VStack(spacing: 0) {
                Capsule()
                    .fill(Asset.Color.handleGray.color)
                    .frame(width: 60, height: 6)
                    .padding(.top, Layout.Spacing.s)

                header
                    .padding(.top, 72)

                VStack(spacing: 20) {
                    nameField
                    urlField
                }
                .padding(.horizontal, Layout.Spacing.l)
                .padding(.top, 40)

                agreement
                    .padding(.horizontal, Layout.Spacing.l)
                    .padding(.top, 20)

                addButton
                    .padding(.horizontal, Layout.Spacing.l)
                    .padding(.top, 20)

                Button {
                    focus = nil
                    InterstitialGuard.perform { close(onHowToUse) }
                } label: {
                    Text("playlist_add_how_to_use".localized(fallback: "How to use?"))
                        .font(FontFamily.Poppins.regular.font(size: 14))
                        .foregroundColor(.brand)
                        .underline()
                        .frame(height: 24)
                }
                .buttonStyle(.plain)
                .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: min(554, maxHeight))
            .background(
                TopRoundedShape(radius: 32)
                    .fill(Asset.Color.sheetBackground.color)
                    .ignoresSafeArea(edges: .bottom)
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .toast(message: $toastMessage)
        .onTapGesture { focus = nil }
        .suppressesAppOpenAd()
    }
}

// MARK: - Sections

private extension AddStreamSheetView {
    var header: some View {
        ZStack {
            Text("playlist_add_stream_title".localized(fallback: "Add Stream"))
                .font(FontFamily.Poppins.medium.font(size: 20))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, Layout.Spacing.xxxl)

            HStack {
                Button {
                    focus = nil
                    InterstitialGuard.perform { close(nil) }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.leading, 14)
                Spacer()
            }
        }
        .frame(height: 24)
    }

    var nameField: some View {
        VStack(spacing: 10) {
            FormFieldTitle(title: "playlist_add_stream_name_label".localized(fallback: "Stream Name"))
            TextField(
                "",
                text: $streamName,
                prompt: Text("playlist_add_stream_name_placeholder".localized(fallback: "Stream Name"))
                    .foregroundColor(Asset.Color.textSubtitle.color)
            )
            .focused($focus, equals: .name)
            .submitLabel(.next)
            .onSubmit { focus = .url }
            .formFieldBox(background: Asset.Color.cardBackground.color, cornerRadius: 14)
        }
    }

    var urlField: some View {
        VStack(spacing: 10) {
            FormFieldTitle(
                title: "playlist_add_stream_url_label".localized(
                    fallback: "Stream URL (Support network protocols: http, ftp, mms, rtsp, rtp, udp, ...)"
                ),
                isRequired: true
            )
            TextField(
                "",
                text: $streamURL,
                prompt: Text("playlist_add_stream_url_placeholder".localized(fallback: "https://example.com/index.mp4"))
                    .foregroundColor(Asset.Color.textSubtitle.color)
            )
            .keyboardType(.URL)
            .focused($focus, equals: .url)
            .submitLabel(.done)
            .onSubmit { focus = nil }
            .formFieldBox(background: Asset.Color.cardBackground.color, cornerRadius: 14)
        }
    }

    var agreement: some View {
        HStack(alignment: .top, spacing: Layout.Spacing.s) {
            Button {
                isAgreementSelected.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: Layout.CornerRadius.medium)
                        .fill(isAgreementSelected ? Color.brand : Color.clear)
                    RoundedRectangle(cornerRadius: Layout.CornerRadius.medium)
                        .stroke(isAgreementSelected ? Color.brand : Asset.Color.cardBorder.color, lineWidth: 1)
                    if isAgreementSelected {
                        Asset.Image.Movies.icAgreementSelect.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .padding(3)
                    }
                }
                .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)

            (
                Text("playlist_add_agreement_prefix".localized(fallback: "By tapping Add, you agree to our "))
                    .foregroundColor(Asset.Color.textCaption.color)
                    + Text("playlist_add_license_agreement".localized(fallback: "License Agreement"))
                    .foregroundColor(.brand)
            )
            .font(FontFamily.Poppins.regular.font(size: 14))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .onTapGesture { isAgreementSelected.toggle() }
            .padding(.top, -2)
        }
    }

    var addButton: some View {
        Button(action: submit) {
            HStack(spacing: Layout.Spacing.s) {
                Image(systemName: "plus")
                Text("playlist_add_stream_button".localized(fallback: "Add Stream"))
                    .font(FontFamily.Poppins.medium.font(size: 16))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.gradient(colors: [Asset.Color.brandMaroonDark.color, Asset.Color.brandMaroon.color, Asset.Color.brandMaroonDark.color], cornerRadius: 25))
    }
}

// MARK: - Submit

private extension AddStreamSheetView {
    func submit() {
        focus = nil
        guard isAgreementSelected else {
            toastMessage = "playlist_add_agreement_required_error".localized(
                fallback: "Please agree to the License Agreement before adding a playlist."
            )
            return
        }

        let url = streamURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValid(url) else {
            toastMessage = "playlist_add_invalid_or_empty_error".localized(fallback: "Playlist is invalid or empty.")
            return
        }

        let name = streamName.trimmingCharacters(in: .whitespacesAndNewlines)
        close { onSubmit(.stream(name: name, url: url)) }
    }

    func isValid(_ value: String) -> Bool {
        guard !value.isEmpty,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else { return false }
        return true
    }
}
