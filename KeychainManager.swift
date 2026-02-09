//
//  KeychainManager.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation
import Security

// 기존 데이터 모델 유지
struct UserInfo: Codable {
    var accessToken: String?
    var refreshToken: String?
}

final class KeychainManager: @unchecked Sendable {
    
    static let standard = KeychainManager()
    
    private init() {}
    
    // MARK: - Public API (비즈니스 로직)
    
    /// UserInfo 객체를 JSON으로 인코딩하여 저장
    public func saveSession(_ session: UserInfo, for key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else {
            return false
        }
        return save(data, for: key)
    }
    
    /// 저장된 데이터를 불러와 UserInfo 객체로 디코딩
    public func loadSession(for key: String) -> UserInfo? {
        guard let data = load(key: key),
            let session = try? JSONDecoder().decode(
                UserInfo.self,
                from: data
            ) else {
            return nil
        }
        return session
    }
    
    /// 해당 키의 데이터를 삭제
    public func deleteSession(for key: String) {
        delete(key: key)
    }
    
    // MARK: - Private Raw Keychain Operations (키체인 저수준 로직)
    
    @discardableResult
    private func save(_ data: Data, for key: String) -> Bool {
        // 기존 값이 있다면 삭제 후 저장 (중복 방지)
        if load(key: key) != nil {
            delete(key: key)
        }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain Save Failed: \(status)")
        }
        
        return status == errSecSuccess
    }
    
    private func load(key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status != errSecSuccess {
            // 데이터가 없거나 에러 발생 시 로그 출력 (필요 시 주석 해제)
            // print("Keychain Load Failed or Empty: \(status)")
        }
        
        return item as? Data
    }
    
    @discardableResult
    private func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // 삭제할 아이템이 없는 경우(errSecItemNotFound)는 실패가 아님
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Keychain Delete Failed: \(status)")
        }
        
        return status == errSecSuccess
    }
}
