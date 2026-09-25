//
//  DetailXtreamAspectRatioOption.swift
//  I340_IPTV
//

import CoreGraphics
import Foundation

enum DetailXtreamAspectRatioOption: Equatable {
    case `default`
    case cropToFill
    case ratio(CGFloat)

    var title: String {
        switch self {
        case .default:
            return "xtream_aspect_default".localized
        case .cropToFill:
            return "xtream_aspect_crop_to_fill".localized
        case .ratio(let value):
            if abs(value - (4.0 / 3.0)) < 0.001 {
                return "4:3"
            } else if abs(value - (5.0 / 4.0)) < 0.001 {
                return "5:4"
            } else if abs(value - (16.0 / 9.0)) < 0.001 {
                return "16:9"
            } else if abs(value - (9.0 / 16.0)) < 0.001 {
                return "9:16"
            } else if abs(value - (16.0 / 10.0)) < 0.001 {
                return "16:10"
            } else if abs(value - 2.21) < 0.001 {
                return "2.21:1"
            } else if abs(value - 2.35) < 0.001 {
                return "2.35:1"
            } else {
                return "2.39:1"
            }
        }
    }

    static func == (lhs: DetailXtreamAspectRatioOption, rhs: DetailXtreamAspectRatioOption) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default), (.cropToFill, .cropToFill):
            return true
        case (.ratio(let lhsValue), .ratio(let rhsValue)):
            return abs(lhsValue - rhsValue) < 0.001
        default:
            return false
        }
    }
}
