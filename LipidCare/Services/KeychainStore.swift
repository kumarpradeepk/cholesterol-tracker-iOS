import Foundation
import Security

/// Minimal Keychain wrapper for the FatSecret API credentials.
enum KeychainStore {
    private static let service = "com.lipidcare.app.fatsecret"

    static func set(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // Convenience accessors
    static var fatSecretClientId: String {
        get { get("clientId") ?? "" }
        set { set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), for: "clientId") }
    }
    static var fatSecretClientSecret: String {
        get { get("clientSecret") ?? "" }
        set { set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), for: "clientSecret") }
    }
    static var hasCredentials: Bool {
        !fatSecretClientId.isEmpty && !fatSecretClientSecret.isEmpty
    }
}
