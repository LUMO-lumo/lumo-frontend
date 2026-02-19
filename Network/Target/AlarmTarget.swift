//
//  AlarmTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation

import Alamofire
import Moya

enum AlarmTarget {
    case updateSetting(duration: Int)
}

extension AlarmTarget: TargetType {
    
    var baseURL: URL {
        return URL(string: AppConfig.baseURL)!
    }
    
    var path: String {
        return "/api/setting"
    }
    
    var method: Moya.Method {
        return .patch
    }

    var task: Moya.Task {
        switch self {
        case .updateSetting(let duration):
            let params: [String: Any] = [
                "alarmOffMissionDefaultDuration": duration
            ]
            return .requestParameters(
                parameters: params,
                encoding: JSONEncoding.default
            )
        }
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
