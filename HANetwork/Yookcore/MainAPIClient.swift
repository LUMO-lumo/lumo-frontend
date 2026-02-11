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
    
    // 1. 토큰 제공자 인스턴스 (보내주신 TokenProvider 사용)
    private let tokenProvider = TokenProvider()
    
    // 2. 토큰 갱신 및 헤더 주입을 담당하는 인터셉터 생성
    // (lazy var를 사용하여 tokenProvider가 초기화된 후 생성되도록 함)
    private lazy var tokenInterceptor = AccessTokenRefresher(tokenProviding: tokenProvider)
    
    // 3. 인터셉터가 적용된 Alamofire 세션 생성
    private lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 30 // 타임아웃 30초
        
        // ✨ 핵심: 여기에 interceptor를 주입하여 모든 요청에 토큰 자동 포함
        return Session(configuration: configuration, interceptor: tokenInterceptor)
    }()
    
    // 4. 커스텀 세션을 사용하는 MoyaProvider 생성
    // 기존: private let provider = MoyaProvider<T>()
    private lazy var provider = MoyaProvider<T>(session: session)
    
    // -------------------------------------------------------------


    func request<D: Codable>(_ target: T, completion: @escaping (Result<D, MainAPIError>) -> Void) {
        
        // 1. 요청 시작 로그
        print("\n🚀 [API Request] \(target.method.rawValue) \(target.path) 요청 시작")
        
        provider.request(target) { result in
            switch result {
            case .success(let response):
                // 원본 데이터를 문자열로 변환 (서버 에러 메시지 확인용)
                let responseString = String(data: response.data, encoding: .utf8) ?? "Data encoding failed"
                
                // 2. HTTP 상태 코드 에러 체크 (200~299가 아닌 경우)
                guard (200...299).contains(response.statusCode) else {
                    // 500 에러 발생 시 서버가 보낸 Raw Json 출력
                    print("📩 서버 응답(Raw): \(responseString)")
                    print("❌ 데이터 매핑 또는 상태 코드 에러: statusCode(Status Code: \(response.statusCode), Data Length: \(response.data.count))")
                    
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
                            print("⚠️ Success is true but Result is nil")
                            completion(.failure(.decodingError))
                        }
                    } else {
                        // success가 false인 경우 (비즈니스 로직 에러)
                        print("📩 서버 응답(Raw): \(responseString)")
                        print("⚠️ [Logic Error] Code: \(wrapper.code), Message: \(wrapper.message)")
                        completion(.failure(.logicError(code: wrapper.code, message: wrapper.message)))
                    }
                    
                } catch {
                    // JSON 변환 실패 시
                    print("📩 서버 응답(Raw): \(responseString)")
                    print("❌ [Decoding Error] 변환 실패: \(error)")
                    
                    completion(.failure(.decodingError))
                }
                
            case .failure(let error):
                // 아예 통신조차 안 된 경우
                print("❌ [Network Error] 통신 실패: \(error.localizedDescription)")
                completion(.failure(.unknownError(error)))
            }
        }
    }
}
