//
//  APICode.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/8/26.
//

import Foundation

// [수정] 컴파일 에러 해결을 위해 디코더 초기화 구문 수정
enum APICode: String, Codable {
    case success = "SUCCESS"
    case invalidToken = "AUTH-001"
    case notFound = "COMMON-404"
    case serverError = "COMMON-500"
    case unknown
    
    // 디코딩 시 정의되지 않은 값이 오면 .unknown으로 처리하는 안전한 로직
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = APICode(rawValue: rawValue) ?? .unknown
    }
}
