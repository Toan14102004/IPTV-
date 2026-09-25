//
//  String+LocalizedFallback.swift
//  I340_IPTV
//

import Foundation

extension String {
    /// The translation of this key, or `fallback` when the key has no translation.
    func localized(fallback: String) -> String {
        let value = localized
        return value == self || value.isEmpty ? fallback : value
    }
}
