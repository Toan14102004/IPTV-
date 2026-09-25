//
//  PaywallViewCoordinator.swift
//  I340_IPTV
//

import Foundation

extension PaywallView {
    struct Coordinator: BaseCoordinator {
        enum Alert: BaseAlert {
            /// `finishes`: nil keeps the paywall open, otherwise closing the message closes the
            /// paywall with that `isPurchased` value.
            case message(title: String, text: String, finishes: Bool?)
            /// Hidden "enter premium code" prompt (long press on the title).
            case voucher
        }

        var alert: Alert?
    }
}
