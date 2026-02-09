//
//  TokenProvider.swift
//  Lumo
//
//  Created by 김승겸 on 2/9/26.
//

import Foundation
import Moya

// ⭐️ 1. 프로토콜 채택 및 Sendable 적용
class TokenProvider: @unchecked Sendable, TokenProviding {
    
    // ⭐️ 2. 싱글톤 패턴 유지 (가장 중요한 부분)
    static let shared = TokenProvider()
    
    // 3. 내부 프로퍼티
    private let keyChain = KeychainManager.standard
    private let sessionKey = "userSession"
    private let provider = MoyaProvider<AuthRouter>() // 토큰 갱신 요청용
    
    private init() {}
    
    // MARK: - TokenProperty
    
    var accessToken: String? {
        get {
            return keyChain.loadSession(for: sessionKey)?.accessToken
        }
        set {
            // ⭐️ 수정됨: 기존 세션이 없으면 새로 만들어서라도 저장해야 함
            var userInfo = keyChain.loadSession(for: sessionKey) ?? UserInfo(accessToken: nil, refreshToken: nil)
            userInfo.accessToken = newValue
            
            // 저장 실패 시 로그 출력
            if !keyChain.saveSession(userInfo, for: sessionKey) {
                print("❌ Access Token 저장 실패")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            return keyChain.loadSession(for: sessionKey)?.refreshToken
        }
        set {
            // ⭐️ 수정됨: 위와 동일 로직
            var userInfo = keyChain.loadSession(for: sessionKey) ?? UserInfo(accessToken: nil, refreshToken: nil)
            userInfo.refreshToken = newValue
            
            if !keyChain.saveSession(userInfo, for: sessionKey) {
                print("❌ Refresh Token 저장 실패")
            }
        }
    }
    
    // MARK: - Refresh Logic
    
    /// 토큰 갱신 요청 (워크북 로직 이식)
    func refreshToken(completion: @escaping (String?, Error?) -> Void) {
        // 현재 저장된 리프레시 토큰 가져오기
        guard let currentRefreshToken = self.refreshToken else {
            let error = NSError(domain: "Lumo", code: -1, userInfo: [NSLocalizedDescriptionKey: "저장된 Refresh Token이 없습니다."])
            completion(nil, error)
            return
        }
        
        // AuthRouter를 통해 갱신 요청
        provider.request(.sendRefreshToken(refreshToken: currentRefreshToken)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                do {
                    // 응답 코드가 200번대인지 확인 (Moya 기능)
                    let filteredResponse = try response.filterSuccessfulStatusCodes()
                    
                    // 디코딩
                    let tokenData = try JSONDecoder().decode(TokenResponse.self, from: filteredResponse.data)
                    
                    if tokenData.isSuccess {
                        // ⭐️ 중요: 성공 시 내부 프로퍼티(Setter)를 통해 키체인에 자동 저장됨
                        self.accessToken = tokenData.result.accessToken
                        self.refreshToken = tokenData.result.refreshToken
                        
                        print("✅ 토큰 갱신 및 저장 성공")
                        completion(tokenData.result.accessToken, nil)
                    } else {
                        // 서버 로직 실패 (예: 리프레시 토큰도 만료됨)
                        let error = NSError(domain: "Lumo", code: -2, userInfo: [NSLocalizedDescriptionKey: "토큰 갱신 실패: \(tokenData.message)"])
                        completion(nil, error)
                    }
                } catch {
                    print("❌ 토큰 갱신 디코딩 에러: \(error)")
                    completion(nil, error)
                }
                
            case .failure(let error):
                print("❌ 토큰 갱신 네트워크 에러: \(error)")
                completion(nil, error)
            }
        }
    }
}
