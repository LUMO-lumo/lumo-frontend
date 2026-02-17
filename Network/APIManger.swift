//
//  APIManager.swift
//  Lumo
//
//  Created by 김승겸 on 2/9/26.
//

import Foundation
import Moya
import Alamofire

class APIManager: @unchecked Sendable {
    static let shared = APIManager()
    
    // 1. 토큰 관리 객체들
    private let tokenProvider: TokenProviding
    private let accessTokenRefresher: AccessTokenRefresher // (요청 헤더 주입 및 로그아웃 담당)
    private let tokenInterceptor: TokenInterceptor         // 👈 [NEW] 서버 응답 헤더 감시자 (이름 변경됨)
    
    // 2. 네트워크 세션 & 로거
    private let session: Session
    private let loggerPlugin: PluginType
    
    private init() {
        // A. Provider 생성
        let provider = TokenProvider()
        self.tokenProvider = provider
        
        // B. Interceptor 생성
        // - accessTokenRefresher: 요청 나갈 때 헤더 붙이기 (RequestAdapter)
        // - tokenInterceptor: 응답 들어올 때 헤더 검사하기 (EventMonitor)
        self.accessTokenRefresher = AccessTokenRefresher(tokenProviding: provider)
        self.tokenInterceptor = TokenInterceptor(tokenProvider: provider) // 👈 클래스 이름 변경 반영
        
        // C. Session 설정 (가장 중요!)
        // Alamofire 세션에 Interceptor와 Monitor를 모두 등록합니다.
        self.session = Session(
            interceptor: accessTokenRefresher,
            eventMonitors: [tokenInterceptor] // 👈 여기에 등록해야 헤더 감시 작동
        )
        
        // D. 로거 플러그인 설정
        self.loggerPlugin = NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
    }
    
    /// 실제 API 요청용 MoyaProvider
    public func createProvider<T: TargetType>(for targetType: T.Type) -> MoyaProvider<T> {
        return MoyaProvider<T>(
            session: session,         // 헤더 감시 기능이 포함된 세션 사용
            plugins: [loggerPlugin]   // 로거 플러그인 포함
        )
    }
}
