//
//  AccessTokenRefresher.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation
import Alamofire

final class AccessTokenRefresher: RequestInterceptor, @unchecked Sendable {
    // Inject the token provider to avoid main-actor access during property initialization
    private let tokenProvider: TokenProvider

    // Concurrency-safe state
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []
    private let lock = NSLock()

    // Designated initializer to inject the main-actor isolated singleton at call site safely
    // Caller must now always pass the TokenProvider explicitly
    init(tokenProvider: TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    // MARK: - Adapt (request adaptation before send)
    nonisolated(nonsending)
    func adapt(_ urlRequest: URLRequest, using state: RequestAdapterState, completion: @escaping (Result<URLRequest, Error>) -> Void) async {
        // Read token on the main actor, but do not send `completion` across the actor hop
        let token: String? = await MainActor.run { tokenProvider.accessToken }

        var modifiedRequest = urlRequest
        if let token {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        completion(.success(modifiedRequest))
    }

    // MARK: - Retry (on failure)
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // Only handle 401 Unauthorized
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }

        lock.lock()
        requestsToRetry.append(completion)

        if isRefreshing {
            lock.unlock()
            return
        }

        isRefreshing = true
        lock.unlock()

        print("🔄 토큰 만료 감지 -> 갱신 시도")

        // Call refresh on the main actor if needed
        Task { [weak self] in
            guard let self else { return }

            await MainActor.run {
                tokenProvider.refreshToken { [weak self] newToken, refreshError in
                    guard let self = self else { return }

                    self.lock.lock()
                    defer {
                        self.requestsToRetry.removeAll()
                        self.isRefreshing = false
                        self.lock.unlock()
                    }

                    if let _ = newToken {
                        print("✅ 토큰 갱신 성공 -> 대기중인 요청 \(self.requestsToRetry.count)개 재시도")
                        self.requestsToRetry.forEach { $0(.retry) }
                    } else {
                        print("❌ 토큰 갱신 실패 -> 로그아웃 처리 필요")
                        self.requestsToRetry.forEach { $0(.doNotRetryWithError(refreshError ?? NSError(domain: "TokenError", code: 401))) }
                    }
                }
            }
        }
    }
}

