//
//  XtreamCredentialStore.swift
//  I340_IPTV
//

import Foundation
import Security

/// Keychain storage for Xtream provider passwords.
///
/// The playlist row in Core Data only keeps a reference (`pwref`); the password itself lives
/// here with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, so it never reaches an iCloud or
/// iTunes backup the way a plain Core Data column would.
enum XtreamCredentialStore {
    private static let service = "com.limgrow.iptv.xtream.credential"

    /// Reference to hand to `XtreamProfilePayload`; the password is reachable only through it.
    static func makeReference() -> String {
        UUID().uuidString
    }

    @discardableResult
    static func save(password: String, for reference: String) -> Bool {
        guard !reference.isEmpty, let data = password.data(using: .utf8) else { return false }

        // SecItemUpdate cannot create a missing item, so replace unconditionally.
        SecItemDelete(baseQuery(for: reference) as CFDictionary)

        var attributes = baseQuery(for: reference)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func password(for reference: String) -> String? {
        guard !reference.isEmpty else { return nil }

        var query = baseQuery(for: reference)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(reference: String) -> Bool {
        guard !reference.isEmpty else { return false }
        let status = SecItemDelete(baseQuery(for: reference) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func baseQuery(for reference: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference
        ]
    }
}
