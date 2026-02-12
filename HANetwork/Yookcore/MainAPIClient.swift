//
//  MainAPIClient.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.

import Foundation
import Moya
import Alamofire


class MainAPIClient<T: TargetType> {
    
    // -------------------------------------------------------------
    // ✅ [수정] 토큰 관리자 및 인터셉터 연결 설정
    // -------------------------------------------------------------
    
    // 1. 토큰 제공자 인스턴스
    private let tokenProvider = TokenProvider()
    
    // 2. 토큰 갱신 및 헤더 주입을 담당하는 인터셉터 생성
    private lazy var tokenInterceptor = AccessTokenRefresher(tokenProviding: tokenProvider)
    
    // 3. 인터셉터가 적용된 Alamofire 세션 생성
    private lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 30
        
        // Interceptor는 '갱신(Retry)'을 위해 유지
        return Session(configuration: configuration, interceptor: tokenInterceptor)
    }()
    
    // 4. 커스텀 세션을 사용하는 MoyaProvider 생성
    // ✅ [핵심 수정] endpointClosure를 추가하여 요청 생성 시점에 토큰을 강제로 헤더에 박아넣음
    private lazy var provider = MoyaProvider<T>(
        endpointClosure: { [weak self] target in
            // 1. 기본 Endpoint 생성
            var endpoint = MoyaProvider.defaultEndpointMapping(for: target)
            
            // 2. 토큰이 있다면 Authorization 헤더 추가 (Interceptor가 놓치는 경우 대비)
            if let token = self?.tokenProvider.accessToken, !token.isEmpty {
                endpoint = endpoint.adding(newHTTPHeaderFields: ["Authorization": "Bearer \(token)"])
            }
            
            return endpoint
        },
        session: session
    )
    
    // -------------------------------------------------------------
    // ✅ [추가] 외부에서 토큰 존재 여부 확인 가능
    var isLoggedIn: Bool {
        return tokenProvider.accessToken != nil
    }

    func request<D: Codable>(_ target: T, completion: @escaping (Result<D, MainAPIError>) -> Void) {
        
        // 1. 요청 시작 로그 (토큰 보유 여부도 같이 출력하여 디버깅)
        let tokenStatus = isLoggedIn ? "O" : "X"
        print("\n🚀 [API Request] \(target.method.rawValue) \(target.path) 요청 시작 (Token: \(tokenStatus))")
        
        provider.request(target) { result in
            switch result {
            case .success(let response):
                // 원본 데이터를 문자열로 변환
                let responseString = String(data: response.data, encoding: .utf8) ?? "Data encoding failed"
                
                // 2. HTTP 상태 코드 에러 체크 (200~299가 아닌 경우)
                guard (200...299).contains(response.statusCode) else {
                    print("📩 서버 응답(Raw): \(responseString)")
                    print("❌ 데이터 매핑 또는 상태 코드 에러: statusCode(Status Code: \(response.statusCode))")
                    
                    completion(.failure(.serverError(response.statusCode)))
                    return
                }
                
                // 3. 디코딩 및 비즈니스 로직 처리
                do {
                    let wrapper = try JSONDecoder().decode(MainAPIResponse<D>.self, from: response.data)
                    
                    if wrapper.success {
                        print("✅ [API Success] \(target.path) 요청 성공")
                        
                        if let data = wrapper.result {
                            completion(.success(data))
                        } else {
                            // Result가 없어도 성공으로 칠지, 에러로 칠지는 서버 스펙에 따라 다름
                            print("⚠️ Success is true but Result is nil")
                            completion(.failure(.decodingError))
                        }
                    } else {
                        // success가 false인 경우
                        print("📩 서버 응답(Raw): \(responseString)")
                        print("⚠️ [Logic Error] Code: \(wrapper.code), Message: \(wrapper.message)")
                        completion(.failure(.logicError(code: wrapper.code, message: wrapper.message)))
                    }
                    
                } catch {
                    print("📩 서버 응답(Raw): \(responseString)")
                    print("❌ [Decoding Error] 변환 실패: \(error)")
                    
                    completion(.failure(.decodingError))
                }
                
            case .failure(let error):
                print("❌ [Network Error] 통신 실패: \(error.localizedDescription)")
                completion(.failure(.unknownError(error)))
            }
        }
    }
}
