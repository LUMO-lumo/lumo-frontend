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
    var baseURL: URL { return URL(string: AppConfig.baseURL)! }
    var headers: [String : String]? {
            // 1. 기본 헤더 설정
            var header = ["Content-Type": "application/json"]
            
            // 2. 키체인에서 저장된 토큰 꺼내오기
            // (LoginViewModel에서 저장할 때 썼던 키 "userSession"과 똑같아야 합니다)
            if let userInfo: UserInfo = KeychainManager.standard.loadSession(for: "userSession") {
                
                // 3. 헤더에 토큰 추가 (Bearer + 공백 + 토큰)
                header["Authorization"] = "Bearer \(userInfo.accessToken ?? "토큰 없음")"
                
                print("🔑 헤더에 토큰 추가됨: \(userInfo.accessToken ?? "토큰 없음")")
            }
            
            return header
        }
    }
