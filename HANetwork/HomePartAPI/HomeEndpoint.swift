//
//  HomeEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire

enum HomeEndpoint: @MainActor MainEndpoint {
    // 날짜 문자열을 인자로 받도록 변경
    case getHomeInfo(today: String)

    var path: String { "/api/home" }
    var method: Moya.Method { .get }
    
    var task: Moya.Task {
        switch self {
        case .getHomeInfo(let today):
            // [수정 2] 파라미터 추가 ('today' 키값 필수)
            // GET 요청이므로 쿼리 스트링으로 보냅니다.
            return .requestParameters(
                parameters: ["today": today],
                encoding: URLEncoding.queryString
            )
        }
    }
}
