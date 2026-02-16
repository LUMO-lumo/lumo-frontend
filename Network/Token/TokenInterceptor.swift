//
//  TokenInterceptor.swift
//  Lumo
//
//  Created by 김승겸 on 2/16/26.
//

import Foundation
import Alamofire

final class TokenInterceptor: EventMonitor, @unchecked Sendable {
    
    let tokenProvider: TokenProviding
    
    init(tokenProvider: TokenProviding) {
        self.tokenProvider = tokenProvider
    }
    
    // [수정 1] <Value> 제네릭을 사용하여 'Any' 오류 해결
    // Alamofire는 어떤 타입(Value)이 오든 상관없이 이 메서드를 호출합니다.
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        guard let httpResponse = response.response else { return }
        
        // 1. 헤더에서 'Authorization' 확인
        if let newAccessToken = httpResponse.headers.value(for: "Authorization") {
            
            // 2. "Bearer " 접두어 및 공백 제거
            let cleanToken = newAccessToken.replacingOccurrences(of: "Bearer ", with: "").trimmingCharacters(in: .whitespaces)
            
            // [수정 2] MainActor 오류 해결을 위해 비동기 작업으로 감쌈
            AsyncTask { @MainActor in
                // 3. 기존 토큰과 다르면 업데이트
                // (이제 tokenProvider가 AnyObject이므로 let이어도 수정 가능)
                if cleanToken != self.tokenProvider.accessToken {
                    print("🔄 [TokenInterceptor] 서버가 새 토큰을 발급했습니다. 키체인을 갱신합니다.")
                    self.tokenProvider.accessToken = cleanToken
                }
            }
        }
    }
}
