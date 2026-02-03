//
//  AlarmTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import Moya
import Alamofire

enum AlarmTarget {
    case updateSetting(duration: Int)
}

extension AlarmTarget: TargetType {
    var baseURL: URL { return URL(string: "http://13.124.31.129")! } // Swagger 베이스 URL
    var path: String { return "/api/setting" }
    var method: Moya.Method { return .patch }

    var task: Task {
        switch self {
        case .updateSetting(let duration):
            let params: [String: Any] = ["alarmOffMissionDefaultDuration": duration]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}
