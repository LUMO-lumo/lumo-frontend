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
    
    var refreshToken: String? {
        get {
            guard let userInfo = try? keyChain.loadSession(for: userSessionKey) else {
                return nil
            }
            return userInfo.refreshToken
        }
        set {
            guard var userInfo = try? keyChain.loadSession(for: userSessionKey) else {
                print("⚠️ 리프레시 토큰 업데이트 실패: 저장된 세션 없음")
                return
            }
            
            userInfo.refreshToken = newValue
            
            do {
                try keyChain.saveSession(userInfo, for: userSessionKey)
                print("✅ 유저 리프레시 토큰 갱신됨")
            } catch {
                print("❌ 리프레시 토큰 저장 실패: \(error)")
            }
        }
    }
    
    /// 리프레시 토큰을 사용해 토큰 갱신 요청
    func refreshToken(completion: @escaping (String?, Error?) -> Void) {
        // 수정됨: try? 사용
        guard let userInfo = try? keyChain.loadSession(for: userSessionKey),
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
                        // (내부적으로 try-catch 처리가 되어 있음)
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
    
    // Async/Await 버전 (기존 로직 유지)
    func refreshToken() async throws -> Bool {
        // 'withCheckedThrowingContinuation'은 클로저 방식을 async 방식으로 바꿔줍니다.
        return try await withCheckedThrowingContinuation { continuation in
            
            // 기존에 만들어둔 함수를 호출합니다.
            self.refreshToken { newToken, error in
                if let error = error {
                    // 실패하면 에러를 던집니다.
                    continuation.resume(throwing: error)
                } else if newToken != nil {
                    // 토큰이 있으면 성공(true)을 반환합니다.
                    continuation.resume(returning: true)
                } else {
                    // 에러도 없고 토큰도 없는 이상한 경우 처리
                    continuation.resume(throwing: NSError(domain: "LumoError", code: -999, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"]))
                }
            }
        }
    }
}
