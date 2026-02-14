//
//  MainEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.
//

import Foundation
import Moya

protocol MainEndpoint: TargetType { }

extension MainEndpoint {
    var baseURL: URL {
        // AppConfig.baseURL이 유효하지 않을 경우를 대비해 안전하게 처리하거나
        // 확실하다면 강제 언래핑(!)을 유지합니다.
        return URL(string: AppConfig.baseURL)!
    }
    
    var headers: [String : String]? {
        // 1. 기본 헤더 설정
        var header = ["Content-Type": "application/json"]
        
        // 2. 키체인에서 저장된 토큰 꺼내오기
        do {
            // try를 사용하여 값을 가져옵니다. 실패하면 catch 블록으로 이동합니다.
            let userInfo = try KeychainManager.standard.loadSession(for: "userSession")
            
            if let accessToken = userInfo.accessToken {
                // 3. 헤더에 토큰 추가 (Bearer + 공백 + 토큰)
                header["Authorization"] = "Bearer \(accessToken)"
                
                // 디버깅용 로그 (출시 때는 제거하거나 조건을 거는 것이 좋습니다)
                print("🔑 헤더에 토큰 추가됨")
            } else {
                print("⚠️ 저장된 세션은 있으나 Access Token이 비어있습니다.")
            }
            
        } catch {
            // 4. 에러 발생 시 (로그인이 안 되어 있거나 키체인 오류)
            // 토큰 없이 헤더를 반환하게 되며, API 호출 시 401 Unathorized 에러가 발생할 것입니다.
            print("ℹ️ 토큰 로드 실패 (비로그인 상태 또는 에러): \(error)")
        }
        
        return header
    }
}
