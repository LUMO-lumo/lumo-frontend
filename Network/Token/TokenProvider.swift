//
//  TokenProvider.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation
import Moya

class TokenProvider: TokenProviding {
    
    // 앞선 LoginViewModel에서 저장한 키와 동일하게 맞춤 ("userSession")
    private let userSessionKey = "userSession"
    private let keyChain = KeychainManager.standard
    
    var accessToken: String? {
        get {
            // 수정됨: try?를 사용하여 에러 발생 시 nil 반환
            guard let userInfo = try? keyChain.loadSession(for: userSessionKey) else {
                return nil
            }
            return userInfo.accessToken
        }
        set {
            // 수정됨: loadSession이 실패하면 업데이트 불가하므로 종료
            guard var userInfo = try? keyChain.loadSession(for: userSessionKey) else {
                print("⚠️ 액세스 토큰 업데이트 실패: 저장된 세션 없음")
                return
            }
            
            userInfo.accessToken = newValue
            
            do {
                try keyChain.saveSession(userInfo, for: userSessionKey)
                print("✅ 유저 액세스 토큰 갱신됨")
            } catch {
                print("❌ 액세스 토큰 저장 실패: \(error)")
            }
        }
    }
}
