//
//  HubViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import UIKit

extension HubView {
    final class ViewModel: ObservableObject {
        static let codeLength = 6

        @Published var code = "" {
            didSet {
                let cleaned = String(code.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }.prefix(Self.codeLength))
                if cleaned != code { code = cleaned }
            }
        }
        @Published private(set) var lastCode: String?
        @Published private(set) var isJoining = false
        @Published var unavailableCode: String?
        @Published var toast: String?

        private let identity = RoomIdentity.current

        var isValid: Bool { code.count == Self.codeLength }

        var characters: [String] {
            (0..<Self.codeLength).map { index in
                index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
            }
        }

        func onAppear() {
            Task { @MainActor [weak self] in
                self?.lastCode = RoomJoinCenter.shared.lastCode
            }
        }

        func useLastCode() {
            guard let lastCode else { return }
            code = lastCode
        }

        /// Fills the boxes from the clipboard. A pasted message may carry the code among other words,
        /// so a word of exactly six letters or digits wins over simply taking the first six characters.
        func paste() {
            guard let text = UIPasteboard.general.string else { return }
            let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            code = words.first { $0.count == Self.codeLength } ?? text
        }

        func clear() {
            code = ""
        }

        func editCode() {
            unavailableCode = nil
        }

        func join() {
            guard isValid, !isJoining else { return }
            isJoining = true
            let code = code
            RoomLog.note("Room tab: join tapped for \(code) → \(Configs.Network.roomsServerURL)")
            let room = RoomService()
            Task { @MainActor [weak self, identity] in
                do {
                    _ = try await room.joinRoom(code: code, identity: identity)
                    guard let self else { return }
                    isJoining = false
                    RoomJoinCenter.shared.hold(room, for: code)
                    RoomJoinCenter.shared.lastCode = code
                    lastCode = code
                    self.code = ""
                    AppNavigator.push(.watchRoom(code: code))
                } catch {
                    room.leaveRoom()
                    guard let self else { return }
                    isJoining = false
                    let failure = error as? RoomError
                    RoomLog.note("Room tab: join \(code) failed with \(failure?.code ?? "\(error)")")
                    switch failure?.code {
                    case "ROOM_NOT_FOUND", "ROOM_ENDED", "VALIDATION_ERROR":
                        unavailableCode = code
                    default:
                        let message = "room_join_failed".localized(fallback: "Couldn't join the room.")
                        toast = failure.map { "\(message) (\($0.code))" } ?? message
                    }
                    Logger.e("Join room failed", error)
                }
            }
        }
    }
}
