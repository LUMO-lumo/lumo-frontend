//
//  TokenInterceptor.swift
//  Lumo
//
//  Created by 김승겸 on 2/16/26.
//

import Alamofire
import Foundation

final class TokenInterceptor: EventMonitor, @unchecked Sendable {
    
    let tokenProvider: TokenProviding
    
    init(tokenProvider: TokenProviding) {
        self.tokenProvider = tokenProvider
    }
    
    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard let httpResponse = response.response else { return }
        
        // 헤더에서 'Authorization' 확인
        if let newAccessToken = httpResponse.headers.value(for: "Authorization") {
            
            let cleanToken = newAccessToken
                .replacingOccurrences(of: "Bearer ", with: "")
                .trimmingCharacters(in: .whitespaces)      
            // MainActor 오류 해결을 위해 비동기 작업으로 감쌈
            AsyncTask { @MainActor in
                // 기존 토큰과 다르면 업데이트
                if cleanToken != self.tokenProvider.accessToken {
                    print("🔄 [TokenInterceptor] 서버가 새 토큰을 발급했습니다. 키체인을 갱신합니다.")
                    self.tokenProvider.accessToken = cleanToken
                }
            }
        }
    }
}
