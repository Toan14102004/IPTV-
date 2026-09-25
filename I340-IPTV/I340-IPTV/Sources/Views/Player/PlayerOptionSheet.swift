//
//  PlayerOptionSheet.swift
//  I340_IPTV
//

import SwiftUI

/// Black bottom sheet of the player: a list of rows, optionally with a check on the selected one.
struct PlayerOptionSheet: View {
    struct Row: Identifiable {
        let id: String
        let title: String
        var icon: AnyView?
        var isSelected = false
        let action: () -> Void
    }

    let rows: [Row]
    /// Rows with a check column (speed, quality, aspect ratio) use the smaller gray font.
    var showsChecks = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    Button(action: row.action) {
                        HStack(spacing: showsChecks ? 3 : 14) {
                            if showsChecks {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .opacity(row.isSelected ? 1 : 0)
                                    .padding(.trailing, 0)
                            } else if let icon = row.icon {
                                icon.frame(width: 22, height: 22)
                            }

                            Text(row.title)
                                .font(showsChecks
                                      ? FontFamily.Poppins.regular.font(size: 14)
                                      : FontFamily.Poppins.medium.font(size: 15))
                                .foregroundColor(showsChecks && !row.isSelected ? Asset.Color.textGray.color : .white)
                                .lineLimit(1)
                                .padding(.leading, showsChecks ? 0 : 0)

                            Spacer(minLength: 0)
                        }
                        .frame(height: showsChecks ? 36 : 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Layout.Spacing.l)
            .padding(.vertical, Layout.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 420)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, Layout.Spacing.s)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }
}
