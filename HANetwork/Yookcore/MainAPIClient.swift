//
//  MainAPIClient.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.

import Foundation
import Moya
import Alamofire


class MainAPIClient<T: TargetType> {
    
    private let tokenProvider = TokenProvider()
    
    // 🚨 [수정] 크래시 방지를 위해 Interceptor 연결 해제
    // (이 부분이 무한 루프 크래시 EXC_BREAKPOINT의 원인이었습니다)
    // private lazy var tokenInterceptor = AccessTokenRefresher(tokenProviding: tokenProvider)
    
    private lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 30
        
        // 🚨 Interceptor 제거
        return Session(configuration: configuration)
    }()
    
    private lazy var provider = MoyaProvider<T>(
        endpointClosure: { [weak self] target in
            var endpoint = MoyaProvider.defaultEndpointMapping(for: target)
            // 토큰 주입 로직은 유지
            if let token = self?.tokenProvider.accessToken, !token.isEmpty {
                endpoint = endpoint.adding(newHTTPHeaderFields: ["Authorization": "Bearer \(token)"])
            }
            return endpoint
        },
        session: session
    )
    
    var isLoggedIn: Bool {
        return tokenProvider.accessToken != nil
    }

    func request<D: Codable>(_ target: T, completion: @escaping (Result<D, MainAPIError>) -> Void) {
        
        // ✅ [안전장치] 로그아웃 상태라면 API 호출 차단 (선택사항, 하지만 크래시 방지에 도움됨)
        if !isLoggedIn {
            // 알람 생성/조회 등 인증이 필요한 API는 여기서 막음
            // (Login API는 제외해야 하지만 현재 구조상 T가 제네릭이라 일괄 적용됨.
            // 만약 Login API도 MainAPIClient를 쓴다면 이 guard문을 제거하세요.)
             // print("🚫 [API Block] 비로그인 상태이므로 요청을 중단합니다.")
             // return
        }
        
        let tokenStatus = isLoggedIn ? "O" : "X"
        print("\n🚀 [API Request] \(target.method.rawValue) \(target.path) (Token: \(tokenStatus))")
        
        provider.request(target) { result in
            switch result {
            case .success(let response):
                guard (200...299).contains(response.statusCode) else {
                    print("❌ [API Fail] Status Code: \(response.statusCode)")
                    completion(.failure(.serverError(response.statusCode)))
                    return
                }
                
                do {
                    let wrapper = try JSONDecoder().decode(MainAPIResponse<D>.self, from: response.data)
                    if wrapper.success {
                        if let data = wrapper.result {
                            completion(.success(data))
                        } else {
                            if let nilResult = Any?.none as? D {
                                completion(.success(nilResult))
                            } else {
                                completion(.failure(.decodingError))
                            }
                        }
                    } else {
                        completion(.failure(.logicError(code: wrapper.code, message: wrapper.message)))
                    }
                } catch {
                    completion(.failure(.decodingError))
                }
                
            case .failure(let error):
                print("❌ [Network Error] \(error.localizedDescription)")
                completion(.failure(.unknownError(error)))
            }
        }
    }
}
