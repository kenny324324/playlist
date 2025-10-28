import Foundation
import Security

enum TokenStorage {
    private static let service = "com.myplaylist.spotify.auth"
    private static let accessTokenAccount = "access_token"
    private static let refreshTokenAccount = "refresh_token"
    private static let expirationDateAccount = "expiration_date"
    private static let codeVerifierAccount = "code_verifier"

    static func saveAccessToken(_ token: String) {
        save(token, account: accessTokenAccount)
    }

    static func loadAccessToken() -> String? {
        loadString(account: accessTokenAccount)
    }

    static func deleteAccessToken() {
        deleteItem(account: accessTokenAccount)
    }

    static func saveRefreshToken(_ token: String) {
        save(token, account: refreshTokenAccount)
    }

    static func loadRefreshToken() -> String? {
        loadString(account: refreshTokenAccount)
    }

    static func deleteRefreshToken() {
        deleteItem(account: refreshTokenAccount)
    }

    static func saveExpirationDate(_ date: Date) {
        save(String(date.timeIntervalSince1970), account: expirationDateAccount)
    }

    static func loadExpirationDate() -> Date? {
        guard let stringValue = loadString(account: expirationDateAccount),
              let timestamp = TimeInterval(stringValue) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    static func deleteExpirationDate() {
        deleteItem(account: expirationDateAccount)
    }

    static func clearAll() {
        deleteAccessToken()
        deleteRefreshToken()
        deleteExpirationDate()
        deleteCodeVerifier()
    }

    static func saveCodeVerifier(_ verifier: String) {
        save(verifier, account: codeVerifierAccount)
    }

    static func loadCodeVerifier() -> String? {
        loadString(account: codeVerifierAccount)
    }

    static func deleteCodeVerifier() {
        deleteItem(account: codeVerifierAccount)
    }

    private static func save(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        case errSecItemNotFound:
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        default:
            break
        }
    }

    private static func loadString(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let stringValue = String(data: data, encoding: .utf8) else {
            return nil
        }
        return stringValue
    }

    private static func deleteItem(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
