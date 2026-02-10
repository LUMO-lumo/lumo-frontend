//
//  APITargetType.swift
//  Lumo
//
//  Created by 김승겸 on 2/9/26.
//

import Foundation

import Moya

/// 모든 타겟이 상속받을 기본 프로토콜
protocol APITargetType: TargetType {}

extension APITargetType {
    
    // 공통 BaseURL 설정 (AppConfig 연결)
    var baseURL: URL {
        // AppConfig.baseURL 문자열을 안전하게 URL로 변환
        guard let url = URL(string: AppConfig.baseURL) else {
            fatalError("⚠️ AppConfig의 BASE_URL이 유효하지 않습니다.")
        }
        return url
    }
    
    // 공통 헤더 설정 (Content-Type 자동 지정)
    var headers: [String: String]? {
        switch task {
        case .requestJSONEncodable, .requestParameters:
            return ["Content-Type": "application/json"]
            
        case .uploadMultipart:
            return ["Content-Type": "multipart/form-data"]
            
        default:
            // 별도 설정이 없으면 기본적으로 JSON으로 간주
            return ["Content-Type": "application/json"]
        }
    }
    
    // 허용할 응답 코드 (200~299만 성공으로 간주)
    // 이 설정을 해두면 400, 500 에러가 왔을 때 자동으로 에러 처리(failure)로 빠진다
    var validationType: ValidationType {
        return .successCodes
    }
}
