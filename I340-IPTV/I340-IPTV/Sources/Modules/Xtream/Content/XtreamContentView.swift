//
//  XtreamContentView.swift
//  I340_IPTV
//

import SwiftUI

/// Movies, series and live TV of one Xtream profile with search and favorites.
struct XtreamContentView: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.s)

            MediaTabs(selected: viewModel.selectedTab, onSelect: viewModel.select)
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.m)

            content
                .padding(.top, Layout.Spacing.m)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !viewModel.isSubscribed {
                NativeAdBannerView(config: .init(adIdNormal: .ADSNativeAdsMediaViewID), height: 196) {
                    MediumNativeAdView(frame: .zero)
                }
            }
        }
        .onAppear(perform: viewModel.refreshFavorites)
        .onChange(of: viewModel.isSearching) { isSearching in
            isSearchFocused = isSearching
        }
    }
}

// MARK: - Header

private extension XtreamContentView {
    var header: some View {
        HStack(spacing: Layout.Spacing.s) {
            BackButton(action: viewModel.didTapBack)
                .frame(width: 24, height: 24)

            Image(viewModel.avatarName)
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .background(Color.white)
                .clipShape(Circle())

            Group {
                if viewModel.isSearching {
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
                } else {
                    Text(viewModel.profileName)
                        .font(FontFamily.Poppins.medium.font(size: 22))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            iconButton(viewModel.isSearching ? "xmark" : "magnifyingglass", action: viewModel.didTapSearch)
            iconButton(nil, asset: Asset.Image.Movies.icFavorite, action: viewModel.didTapFavorites)
        }
        .frame(height: 48)
    }

    func iconButton(_ systemName: String?, asset: ImageAsset? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .medium))
                } else if let asset {
                    asset.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                }
            }
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .frame(width: 34, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content

private extension XtreamContentView {
    @ViewBuilder
    var content: some View {
        if let text = viewModel.placeholderText {
            Text(text)
                .font(FontFamily.Poppins.regular.font(size: 14))
                .foregroundColor(Asset.Color.textGray.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.Spacing.m)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    if viewModel.showsFeatured {
                        featuredCarousel
                    }
                    ForEach(viewModel.sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.bottom, Layout.Spacing.s)
            }
            .simultaneousGesture(DragGesture().onChanged { _ in isSearchFocused = false })
        }
    }

    var featuredCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Layout.Spacing.m) {
                    ForEach(Array(viewModel.featured.enumerated()), id: \.offset) { index, channel in
                        XtreamFeaturedView(channel: channel) {
                            viewModel.open(channel, in: viewModel.featured)
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 84)
            }
            .frame(height: 318)
            .onAppear {
                if viewModel.featured.count > 1 {
                    proxy.scrollTo(1, anchor: .center)
                }
            }
        }
    }

    func sectionView(_ section: XtreamSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(section.title)
                .font(FontFamily.Poppins.medium.font(size: 22))
                .foregroundColor(.white)
                .padding(.horizontal, Layout.Spacing.m)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(section.channels) { channel in
                        XtreamPosterView(
                            channel: channel,
                            isFavorite: viewModel.isFavorite(channel),
                            onTap: { viewModel.open(channel, in: section.channels) },
                            onFavorite: { viewModel.toggleFavorite(channel) }
                        )
                    }
                }
                .padding(.horizontal, Layout.Spacing.m)
            }
            .frame(height: 214)
        }
    }
}
