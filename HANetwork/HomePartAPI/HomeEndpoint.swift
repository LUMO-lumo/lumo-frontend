//
//  HomeEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire


enum HomeEndpoint: MainEndpoint {
    case getHomeInfo

    var path: String { "/api/home" }
    var method: Moya.Method { .get }
    
    var task: Moya.Task {
        return .requestPlain
    }
}
