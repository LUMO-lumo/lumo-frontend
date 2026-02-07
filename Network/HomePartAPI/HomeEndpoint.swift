//
//  HomeEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire

enum HomeEndpoint: YookEndpoint {
    case getHomeInfo

    var path: String { "/api/home" }
    var method: Moya.Method { .get }
    
    // Swift 표준 Task와의 충돌을 방지하기 위해 Moya.Task로 명시합니다.
    var task: Moya.Task {
        return .requestPlain
    }
}
