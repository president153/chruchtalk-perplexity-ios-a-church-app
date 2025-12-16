import Foundation
import Security

/// Service for secure storage of authentication tokens using iOS Keychain
final class KeychainService {

    // MARK: - Singleton

    static let shared = KeychainService()
    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let accessToken = "com.churchtalk.accessToken"
        static let refreshToken = "com.churchtalk.refreshToken"
        static let idToken = "com.churchtalk.idToken"
        static let userId = "com.churchtalk.userId"
        static let churchId = "com.churchtalk.churchId"
    }

    // MARK: - Access Token

    var accessToken: String? {
        get { getValue(for: Keys.accessToken) }
        set { setValue(newValue, for: Keys.accessToken) }
    }

    // MARK: - Refresh Token

    var refreshToken: String? {
        get { getValue(for: Keys.refreshToken) }
        set { setValue(newValue, for: Keys.refreshToken) }
    }

    // MARK: - ID Token

    var idToken: String? {
        get { getValue(for: Keys.idToken) }
        set { setValue(newValue, for: Keys.idToken) }
    }

    // MARK: - User ID

    var userId: String? {
        get { getValue(for: Keys.userId) }
        set { setValue(newValue, for: Keys.userId) }
    }

    // MARK: - Church ID

    var churchId: String? {
        get { getValue(for: Keys.churchId) }
        set { setValue(newValue, for: Keys.churchId) }
    }

    // MARK: - Convenience Methods

    /// Check if user has valid tokens
    var hasValidTokens: Bool {
        return accessToken != nil && refreshToken != nil
    }

    /// Save all authentication tokens
    func saveTokens(accessToken: String, refreshToken: String, idToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
    }

    /// Clear all stored credentials
    func clearAll() {
        accessToken = nil
        refreshToken = nil
        idToken = nil
        userId = nil
        churchId = nil
    }

    // MARK: - Private Keychain Methods

    private func setValue(_ value: String?, for key: String) {
        // First, delete any existing value
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // If value is nil, we're done (just deleting)
        guard let value = value, let data = value.data(using: .utf8) else {
            return
        }

        // Add the new value
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status != errSecSuccess {
            print("⚠️ KeychainService: Failed to save \(key), status: \(status)")
        }
    }

    private func getValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
}

// MARK: - Keychain Error

enum KeychainError: Error, LocalizedError {
    case saveError(OSStatus)
    case readError(OSStatus)
    case deleteError(OSStatus)
    case dataConversionError

    var errorDescription: String? {
        switch self {
        case .saveError(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .readError(let status):
            return "Failed to read from Keychain (status: \(status))"
        case .deleteError(let status):
            return "Failed to delete from Keychain (status: \(status))"
        case .dataConversionError:
            return "Failed to convert data"
        }
    }
}
