import Foundation
import Security

struct UserInfo: Codable {
    var accessToken: String?
    var refreshToken: String?
}

final class KeychainManager: @unchecked Sendable {
    static let standard = KeychainManager()
    private init() {}
    
    func saveSession(_ session: UserInfo, for key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        
        SecItemDelete(query as CFDictionary) // 기존 삭제
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    func loadSession(for key: String) -> UserInfo? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? JSONDecoder().decode(UserInfo.self, from: data) else { return nil }
        
        return session
    }
    
    func deleteSession(for key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
