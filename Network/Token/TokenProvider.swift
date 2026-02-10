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
    private let provider = MoyaProvider<AuthRouter>()
    
    var accessToken: String? {
        get {
            guard let userInfo = keyChain.loadSession(for: userSessionKey) else {
                return nil
            }
            return userInfo.accessToken
        }
        set {
            // 세션이 있을 때만 업데이트 진행
            guard var userInfo = keyChain.loadSession(for: userSessionKey) else {
                return
            }
            userInfo.accessToken = newValue
            
            if keyChain.saveSession(userInfo, for: userSessionKey) {
                print("✅ 유저 액세스 토큰 갱신됨")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            guard let userInfo = keyChain.loadSession(for: userSessionKey) else {
                return nil
            }
            return userInfo.refreshToken
        }
        set {
            guard var userInfo = keyChain.loadSession(for: userSessionKey) else {
                return
            }
            userInfo.refreshToken = newValue
            
            if keyChain.saveSession(userInfo, for: userSessionKey) {
                print("✅ 유저 리프레시 토큰 갱신됨")
            }
        }
    }
    
    /// 리프레시 토큰을 사용해 토큰 갱신 요청
    func refreshToken(completion: @escaping (String?, Error?) -> Void) {
        guard let userInfo = keyChain.loadSession(for: userSessionKey),
            let refreshToken = userInfo.refreshToken else {
            let error = NSError(
                domain: "LumoError",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "저장된 세션이나 리프레시 토큰이 없습니다."]
            )
            completion(nil, error)
            return
        }
        
        provider.request(.sendRefreshToken(refreshToken: refreshToken)) { result in
            switch result {
            case .success(let response):
                // [디버깅] 응답 JSON 확인
                if let jsonString = String(data: response.data, encoding: .utf8) {
                    print("📩 갱신 응답: \(jsonString)")
                }
                
                do {
                    let tokenData = try JSONDecoder().decode(
                        TokenResponse.self,
                        from: response.data
                    )
                    
                    if tokenData.isSuccess {
                        // 프로퍼티 옵저버(set)를 통해 키체인에 자동 저장됨
                        self.accessToken = tokenData.result.accessToken
                        self.refreshToken = tokenData.result.refreshToken
                        
                        completion(self.accessToken, nil)
                    } else {
                        let error = NSError(
                            domain: "LumoError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "토큰 갱신 실패 (Success: false)"]
                        )
                        completion(nil, error)
                    }
                } catch {
                    print("❌ 디코딩 에러: \(error)")
                    completion(nil, error)
                }
                
            case .failure(let error):
                print("❌ 네트워크 에러: \(error)")
                completion(nil, error)
            }
        }
    }
}
