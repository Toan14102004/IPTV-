//
//  AudioOutputSheet.swift
//  I340_IPTV
//

import AVFoundation
import AVKit
import SwiftUI

/// "Audio Output" sheet (Figma): where the sound plays. iOS does not let an app list the
/// AirPlay devices around, so the rows are this iPhone, what the sound goes to right now and
/// an entry for other devices; Connect opens the system picker for those.
struct AudioOutputSheet: View {
    private enum Kind {
        case speaker
        case external
        case other
    }

    private struct Row: Identifiable {
        let id: String
        let kind: Kind
        let title: String
        let subtitle: String
        let icon: ImageAsset
        let isCurrent: Bool
    }

    let onCancel: () -> Void
    let onConnect: () -> Void

    @State private var rows: [Row] = []
    @State private var selectedID = ""

    var body: some View {
        SheetContainer {
            VStack(spacing: Layout.Spacing.m) {
                VStack(spacing: 4) {
                    Text("audio_output_title".localized(fallback: "Audio Output"))
                        .font(Typography.subtitleMedium)
                        .foregroundStyle(Color.text1)
                    Text("audio_output_message".localized(fallback: "Choose where audio should play"))
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.text2)
                }
                .multilineTextAlignment(.center)
                .padding(.top, Layout.Spacing.m)

                VStack(spacing: Layout.Spacing.s) {
                    ForEach(rows) { row in
                        rowView(row)
                    }
                }

                HStack(spacing: Layout.Spacing.sm) {
                    Button(action: onCancel) {
                        Text("cancel".localized(fallback: "Cancel"))
                            .font(Typography.subtitleSmall)
                            .foregroundStyle(Color.text2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.text2, lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: connect) {
                        Text("audio_output_connect".localized(fallback: "Connect"))
                            .font(Typography.subtitleSmall)
                            .foregroundStyle(Color.text4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primary1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Layout.Spacing.m)
            .padding(.bottom, Layout.Spacing.l)
        }
        .onAppear(perform: load)
    }

    private func rowView(_ row: Row) -> some View {
        let isSelected = row.id == selectedID
        return Button { selectedID = row.id } label: {
            HStack(spacing: Layout.Spacing.s) {
                row.icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(Typography.bodyLarge)
                        .lineLimit(1)
                    Text(row.subtitle)
                        .font(Typography.labelSmall)
                        .lineLimit(1)
                        .opacity(isSelected ? 0.85 : 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Asset.Icon.icAudioCheck.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .foregroundStyle(isSelected ? Color.primary1 : Color.text1)
            .padding(Layout.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.background1 : Color.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary1 : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func load() {
        var result: [Row] = []
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        let external = outputs.filter { $0.portType != .builtInSpeaker && $0.portType != .builtInReceiver }

        result.append(Row(
            id: "speaker",
            kind: .speaker,
            title: "audio_output_speaker".localized(fallback: "iPhone Speaker"),
            subtitle: "audio_output_this_device".localized(fallback: "This iPhone"),
            icon: Asset.Icon.icAudioSpeaker,
            isCurrent: external.isEmpty
        ))
        for port in external {
            result.append(Row(
                id: port.uid,
                kind: .external,
                title: port.portName,
                subtitle: Self.kindName(of: port.portType),
                icon: Self.icon(of: port.portType),
                isCurrent: true
            ))
        }
        result.append(Row(
            id: "other",
            kind: .other,
            title: "audio_output_other".localized(fallback: "Other devices"),
            subtitle: "audio_output_other_hint".localized(fallback: "AirPlay, Bluetooth and TVs"),
            icon: Asset.Icon.icAudioTv,
            isCurrent: false
        ))
        rows = result
        selectedID = result.first(where: \.isCurrent)?.id ?? "speaker"
    }

    /// Keeping the current output just closes the sheet; anything else needs the system picker.
    private func connect() {
        if rows.first(where: { $0.id == selectedID })?.isCurrent == true {
            onCancel()
        } else {
            onConnect()
        }
    }

    private static func icon(of type: AVAudioSession.Port) -> ImageAsset {
        switch type {
        case .airPlay, .HDMI, .displayPort: return Asset.Icon.icAudioTv
        default: return Asset.Icon.icAudioBluetooth
        }
    }

    private static func kindName(of type: AVAudioSession.Port) -> String {
        switch type {
        case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP: return "Bluetooth"
        case .airPlay: return "AirPlay"
        case .HDMI, .displayPort: return "HDMI"
        case .headphones: return "Headphones"
        default: return type.rawValue
        }
    }
}

/// Opens the system AirPlay picker from code: its button is tapped on a view that is attached
/// to the window for a moment.
enum AirPlayPicker {
    private static var picker: AVRoutePickerView?

    static func present() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else { return }

        let view = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        view.alpha = 0.01
        window.addSubview(view)
        picker = view
        view.subviews.compactMap { $0 as? UIButton }.first?.sendActions(for: .touchUpInside)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            view.removeFromSuperview()
            if picker === view { picker = nil }
        }
    }
}
