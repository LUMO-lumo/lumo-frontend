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
        
        // 1. 작업을 큐에 넣기 (동시성 문제 방지를 위해 메인 액터 사용 권장되지만, 여기선 일단 진행)
        requestToRetry.append(completion)
        
        if !isRefreshing {
            isRefreshing = true
            
            _Concurrency.Task { [weak self] in
                guard let self = self else { return }
                
                do {
                    // 2. 토큰 갱신 시도 (오래 걸리는 작업)
                    let isSuccess = try await self.tokenProviding.refreshToken()
                    
                    // 3. ✅ [중요] 결과 처리는 반드시 MainActor(한 곳)에서 모아서 실행!
                    // 이렇게 해야 "배열 수정 중에 다른 애가 건드려서 앱이 죽는 문제"를 막습니다.
                    await MainActor.run {
                        self.isRefreshing = false
                        
                        if isSuccess {
                            self.requestToRetry.forEach { $0(.retry) }
                        } else {
                            self.requestToRetry.forEach { $0(.doNotRetry) }
                        }
                        self.requestToRetry.removeAll()
                    }
                    
                } catch {
                    // 4. 실패 시 처리도 MainActor에서
                    await MainActor.run {
                        self.isRefreshing = false
                        self.requestToRetry.forEach { $0(.doNotRetryWithError(error)) }
                        self.requestToRetry.removeAll()
                    }
                }
            }
        }
    }
}
