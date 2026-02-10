//
//  AccessTokenRefresher.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation

import Alamofire

class AccessTokenRefresher: @unchecked Sendable, RequestInterceptor {
    
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
        // 1. 메인 스레드에서 토큰 가져오기 (MainActor.run 사용)
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
        
        // 3. 수정된 요청 반환
        return urlRequest
    }
    
    // MARK: - RequestRetrier
    
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard request.retryCount < 1,
            let response = request.task?.response as? HTTPURLResponse,
            [401, 404].contains(response.statusCode) else {
            return completion(.doNotRetry)
        }
        
        requestToRetry.append(completion)
        
        if !isRefreshing {
            isRefreshing = true
            
            Task { @MainActor in
                tokenProviding.refreshToken { [weak self] newToken, error in
                    guard let self = self else {
                        return
                    }
                    
                    self.isRefreshing = false
                    
                    let result = error == nil
                        ? RetryResult.retry
                        : RetryResult.doNotRetryWithError(error!)
                    
                    self.requestToRetry.forEach { $0(result) }
                    self.requestToRetry.removeAll()
                }
            }
        }
    }
}
