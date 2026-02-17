//
//  AccessTokenRefresher.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation
import Alamofire

class AccessTokenRefresher: @unchecked Sendable, @preconcurrency RequestInterceptor {
    
    private var tokenProviding: TokenProviding
    private var isRefreshing: Bool = false
    private var requestToRetry: [(RetryResult) -> Void] = []
    
    init(tokenProviding: TokenProviding) {
        self.tokenProviding = tokenProviding
    }
    
    // MARK: - RequestAdapter
    
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session
    ) async throws -> URLRequest {
        // 1. 메인 스레드에서 토큰 가져오기
        let accessToken = await MainActor.run {
            return tokenProviding.accessToken
        }
        
        // 2. 요청 헤더 수정
        var urlRequest = urlRequest
        if let accessToken {
            urlRequest.setValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        return urlRequest
    }
    
    // MARK: - RequestRetrier
    @MainActor
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        // 서버가 401(Unauthorized) 또는 403(Forbidden)을 줬다는 것은
        // 자동 갱신조차 불가능한 상태
        if response.statusCode == 401 || response.statusCode == 403 {
            print("🚨 인증 실패(401/403) -> 강제 로그아웃 처리")
            
            // 강제 로그아웃 알림 발송
            NotificationCenter.default.post(name: .forceLogout, object: nil)
            
            // 재시도 하지 않음
            completion(.doNotRetry)
        } else {
            // 그 외 에러(타임아웃 등)는 Alamofire 기본 정책 따름 (또는 재시도 로직 추가 가능)
            completion(.doNotRetryWithError(error))
        }
    }
}
