//
//  PlayVideoRoomViews.swift
//  I340_IPTV
//

import SwiftUI

/// Everything under the player once a room exists: the host, who is watching and the code.
struct RoomPanel: View {
    @ObservedObject var viewModel: PlayVideoView.ViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasViewers {
                Capsule()
                    .fill(Color(hex: 0x9F9F9F))
                    .frame(width: 38, height: 4)
                    .padding(.top, Layout.Spacing.s)
            }

            hostRow
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, viewModel.hasViewers ? Layout.Spacing.s : Layout.Spacing.l)

            if viewModel.relayState == .failed {
                retryRow
                    .padding(.top, Layout.Spacing.s)
            }

            Spacer(minLength: Layout.Spacing.m)

            VStack(spacing: Layout.Spacing.l) {
                if viewModel.hasViewers {
                    watching
                } else {
                    empty
                }
                RoomCodeBox(code: viewModel.roomCode, isCopied: viewModel.isCodeCopied, onTap: viewModel.copyCode)
            }

            Spacer(minLength: Layout.Spacing.m)
        }
    }

    private var hostRow: some View {
        HStack(spacing: Layout.Spacing.s) {
            RoomAvatarView(avatar: viewModel.identity.avatar, size: 36, showsCrown: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.identity.name)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text1)
                    .lineLimit(1)
                Text("watch_together_host".localized(fallback: "Host"))
                    .font(FontFamily.Poppins.regular.font(size: 10))
                    .foregroundStyle(Color.text4)
                    .padding(.horizontal, Layout.Spacing.s)
                    .padding(.vertical, 1)
                    .background(Color.roomLeave, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: viewModel.showInvite) {
                HStack(spacing: Layout.Spacing.xs) {
                    Asset.Icon.icRoomInvite.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("watch_together_invite".localized(fallback: "Invite"))
                        .font(Typography.bodyMedium)
                }
                .foregroundStyle(Color.text2)
                .padding(.horizontal, Layout.Spacing.s)
                .frame(height: 38)
                .background(Color.neutral1, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var retryRow: some View {
        HStack(spacing: Layout.Spacing.s) {
            Text("watch_together_relay_failed".localized(fallback: "Couldn't prepare the video for the room.")
                 + (viewModel.relayErrorCode.map { " (\($0))" } ?? ""))
                .font(Typography.labelSmall)
                .foregroundStyle(Color.text2)
                .lineLimit(2)
            Button(action: viewModel.retryRelay) {
                Text("watch_together_retry".localized(fallback: "Try again"))
                    .font(Typography.labelLarge)
                    .foregroundStyle(Color.primary1)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Layout.Spacing.m)
    }

    private var empty: some View {
        VStack(spacing: Layout.Spacing.s) {
            Asset.Image.imgRoomEmptyPeople.image
                .resizable()
                .frame(width: 48, height: 48)
            VStack(spacing: Layout.Spacing.xs) {
                Text("watch_together_no_one".localized(fallback: "No one has joined yet"))
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.text1)
                Text("watch_together_share_hint".localized(fallback: "Share the code to invite friends"))
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.text2)
            }
            .multilineTextAlignment(.center)
        }
    }

    private var watching: some View {
        RoomWatchingView(
            participants: viewModel.participants,
            count: viewModel.watcherCount,
            onViewList: viewModel.showPeople
        )
    }
}

/// Overlapping avatars, how many are watching and the link to the list.
struct RoomWatchingView: View {
    let participants: [RoomParticipant]
    let count: Int
    let onViewList: () -> Void

    var body: some View {
        VStack(spacing: Layout.Spacing.s) {
            AvatarCluster(participants: participants)

            VStack(spacing: Layout.Spacing.xs) {
                Text("watch_together_watching".localized(fallback: "Watching together"))
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.text1)
                Text(String(
                    format: "watch_together_n_watching".localized(fallback: "%d people watching"),
                    count
                ))
                .font(Typography.bodySmall)
                .foregroundStyle(Color.text2)
            }

            Button(action: onViewList) {
                Text("watch_together_view_list".localized(fallback: "View list"))
                    .underline()
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.primary1)
                    .frame(height: 24)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Pieces

/// Panda avatar; the host's carries a crown on its top right.
struct RoomAvatarView: View {
    let avatar: RoomAvatar
    let size: CGFloat
    var showsCrown = false

    var body: some View {
        avatar.image.image
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .overlay(alignment: .topTrailing) {
                if showsCrown {
                    Asset.Image.imgHostCrown.image
                        .resizable()
                        .frame(width: size / 3, height: size / 3)
                        .offset(x: size * 0.13, y: -size * 0.14)
                }
            }
    }
}

/// Up to three overlapping avatars and a "+N" bubble for the rest.
struct AvatarCluster: View {
    let participants: [RoomParticipant]

    var body: some View {
        let shown = Array(participants.prefix(3))
        let rest = participants.count - shown.count
        HStack(spacing: -10) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, person in
                RoomAvatarView(avatar: RoomAvatar(key: person.avatar), size: 42, showsCrown: index == 0)
                    .padding(.trailing, index == 0 ? 0 : 0)
                    .zIndex(Double(shown.count - index))
            }
            if rest > 0 {
                Text("+\(rest)")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text2)
                    .frame(width: 42, height: 42)
                    .background(Color.neutral1, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
            }
        }
        .padding(.top, 6)
    }
}

struct RoomCodeBox: View {
    let code: String
    let isCopied: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Text("watch_together_room_code".localized(fallback: "Room Code"))
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.text2)
                HStack(spacing: Layout.Spacing.s) {
                    Text(code)
                        .font(FontFamily.Poppins.semiBold.font(size: 20))
                        .foregroundStyle(Color.text1)
                    (isCopied ? Asset.Icon.icImportFieldValid : Asset.Icon.icCopy).image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(isCopied ? Color.accent1 : Color.text1)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(Layout.Spacing.s + Layout.Spacing.xs)
            .background(Color.neutral1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        #if DEBUG
        // Testers: hold the code to copy the room trace for the backend.
        .simultaneousGesture(LongPressGesture(minimumDuration: 1).onEnded { _ in
            UIPasteboard.general.string = RoomLog.text
        })
        #endif
    }
}

/// Toast under the header: green when the room is created, blue when somebody joins, pink when leaving.
struct RoomBannerView: View {
    let banner: PlayVideoView.Banner
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: Layout.Spacing.s) {
            switch banner.kind {
            case .success:
                Asset.Icon.icToastSuccess.image
                    .resizable()
                    .frame(width: 21, height: 21)
            case .joined, .left:
                if let avatar = banner.avatar {
                    RoomAvatarView(avatar: avatar, size: 24)
                }
            }

            Text(banner.text)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.text1)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button(action: onClose) {
                Asset.Icon.icPlayerClose.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.text2)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Layout.Spacing.s + Layout.Spacing.xs)
        .frame(height: 40)
        .background(background, in: Capsule())
        .shadow(.card)
        .padding(.horizontal, Layout.Spacing.m)
    }

    private var background: Color {
        switch banner.kind {
        case .success: Color(hex: 0xC7FFDB)
        case .joined: Color.primary2
        case .left: Color(hex: 0xFFE3E1)
        }
    }
}

// MARK: - Sheets

struct SheetContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: 0x9F9F9F))
                .frame(width: 38, height: 4)
                .padding(.top, Layout.Spacing.sm)
            content
        }
        .frame(maxWidth: .infinity)
        .background(
            TopRoundedShape(radius: 32)
                .fill(Color.background1)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct InviteRoomSheet: View {
    let code: String
    let isCopied: Bool
    let onCopy: () -> Void
    let onShare: () -> Void

    var body: some View {
        SheetContainer {
            VStack(spacing: Layout.Spacing.sm) {
                Text("watch_together_invite_title".localized(fallback: "Invite to this room"))
                    .font(Typography.subtitleMedium)
                    .foregroundStyle(Color.text1)

                RoomCodeBox(code: code, isCopied: isCopied, onTap: onCopy)

                HStack(spacing: Layout.Spacing.sm) {
                    Button(action: onCopy) {
                        HStack(spacing: Layout.Spacing.s) {
                            Asset.Icon.icCopy.image
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("watch_together_copy".localized(fallback: "Copy"))
                                .font(Typography.subtitleSmall)
                        }
                        .foregroundStyle(Color.primary1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary1, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onShare) {
                        HStack(spacing: Layout.Spacing.s) {
                            Asset.Icon.icRoomShare.image
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("watch_together_share".localized(fallback: "Share"))
                                .font(Typography.subtitleSmall)
                        }
                        .foregroundStyle(Color.text4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, Layout.Spacing.s)
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.top, Layout.Spacing.m)
            .padding(.bottom, Layout.Spacing.l)
        }
    }
}

struct PeopleInRoomSheet: View {
    let participants: [RoomParticipant]
    let count: Int

    var body: some View {
        SheetContainer {
            VStack(alignment: .leading, spacing: Layout.Spacing.sm) {
                Text(String(
                    format: "watch_together_people_title".localized(fallback: "People in room (%d)"),
                    count
                ))
                .font(Typography.subtitleMedium)
                .foregroundStyle(Color.text1)
                .padding(.horizontal, Layout.Spacing.m)
                .padding(.top, Layout.Spacing.m)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: Layout.Spacing.s) {
                        ForEach(participants) { person in
                            row(person)
                        }
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                    .padding(.bottom, Layout.Spacing.l)
                }
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
    }

    private func row(_ person: RoomParticipant) -> some View {
        HStack(spacing: Layout.Spacing.s) {
            RoomAvatarView(avatar: RoomAvatar(key: person.avatar), size: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Layout.Spacing.xs) {
                    if person.role == .host {
                        Asset.Image.imgHostCrown.image
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    Text(person.name)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.text1)
                        .lineLimit(1)
                }
                Text(person.role == .host
                     ? "watch_together_host".localized(fallback: "Host")
                     : "watch_together_viewer".localized(fallback: "Viewer"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.Spacing.sm)
        .padding(.vertical, Layout.Spacing.s)
        .frame(maxWidth: .infinity)
        .background(Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
