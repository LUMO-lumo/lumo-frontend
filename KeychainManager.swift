//
//  KeychainManager.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//  Refactored for better error handling
//

import Foundation
import Security

// 기존 데이터 모델 유지
struct UserInfo: Codable {
    var accessToken: String?
    var refreshToken: String?
}

// 에러 정의 (새로 추가됨)
enum KeychainError: Error {
    case itemNotFound       // 저장된 데이터가 없음
    case duplicateItem      // 중복된 아이템 (발생할 일은 적음)
    case invalidItemFormat  // 데이터 형식이 올바르지 않음 (디코딩 실패 등)
    case unexpectedStatus(OSStatus) // 알 수 없는 키체인 오류
    case encodingFailed     // 데이터 인코딩 실패
}

final class KeychainManager: @unchecked Sendable {
    
    static let standard = KeychainManager()
    
    private init() {}
    
    // MARK: - Public API (비즈니스 로직)
    
    /// UserInfo 객체를 JSON으로 인코딩하여 저장
    /// - Throws: KeychainError (인코딩 실패 또는 저장 실패 시)
    public func saveSession(_ session: UserInfo, for key: String) throws {
        do {
            let data = try JSONEncoder().encode(session)
            try save(data, for: key)
        } catch let error as KeychainError {
            throw error // 키체인 에러는 그대로 전달
        } catch {
            throw KeychainError.encodingFailed // 인코딩 에러 변환
        }
    }
    
    /// 저장된 데이터를 불러와 UserInfo 객체로 디코딩
    /// - Returns: UserInfo 객체
    /// - Throws: KeychainError (데이터 없음, 디코딩 실패 등)
    public func loadSession(for key: String) throws -> UserInfo {
        let data = try load(key: key)
        
        do {
            let session = try JSONDecoder().decode(UserInfo.self, from: data)
            return session
        } catch {
            throw KeychainError.invalidItemFormat // 디코딩 실패 시 에러 처리
        }
    }
    
    /// 해당 키의 데이터를 삭제
    /// - Throws: KeychainError (삭제 실패 시)
    public func deleteSession(for key: String) throws {
        try delete(key: key)
    }
    
    // MARK: - Private Raw Keychain Operations (키체인 저수준 로직)
    
    private func save(_ data: Data, for key: String) throws {
        // 기존 데이터가 있으면 삭제 (덮어쓰기 위해)
        // 삭제 시 데이터가 없어도(.errSecItemNotFound) 에러가 아니므로 무시
        try? delete(key: key)
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            // 보안 수준 설정 (잠금 해제 시 접근 가능)
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func load(key: String) throws -> Data {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue!, // 데이터 반환 요청
            kSecMatchLimit: kSecMatchLimitOne // 중복 시 하나만 반환
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = item as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        return data
    }
    
    private func delete(key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // 삭제하려는 아이템이 없는 경우는 성공으로 간주하거나 무시
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
