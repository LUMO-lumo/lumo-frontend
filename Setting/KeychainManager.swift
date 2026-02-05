//
//  KeychainManager.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import Foundation
import Security

class KeychainManager {
    
    static let shared = KeychainManager()
    
    private init() {}
    
    /// 토큰 저장
    func save(token: String, for account: String) {
        // 문자열을 데이터로 변환 (실패 시 리턴)
        guard let data = token.data(using: .utf8) else {
            return
        }
        
        // 1. 저장할 쿼리 (데이터 포함)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // 2. 삭제할 쿼리 (데이터 제외 - 계정 이름만으로 찾음)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        // 기존 데이터 삭제 (기존 데이터 유무와 상관없이 시도)
        SecItemDelete(deleteQuery as CFDictionary)
        
        // 새로 저장
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // (디버깅용) 저장 결과 확인
        if status == errSecSuccess {
            print("Keychain 저장 성공: \(account)")
        } else {
            print("Keychain 저장 실패: \(status)")
        }
    }
    
    /// 토큰 읽기
    func read(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
            let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    /// 토큰 삭제 (로그아웃 시)
    func delete(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
