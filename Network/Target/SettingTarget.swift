//
//  AlarmTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import Moya
import Alamofire

enum SettingTarget {
    case updateSeconds(second: Int)
    case updateTheme(theme: String)
    case updateVoice(voice: String)
    case smartVoice(smartvoice: Bool)
}

extension SettingTarget: TargetType {
    var baseURL: URL { return URL(string: "http://13.124.31.129")! } // Swagger 베이스 URL
    var path: String { return "/api/setting" }
    var method: Moya.Method { return .patch }

    // alarmOffMissionDefaultDuration, theme 항목 수정
    var task:  Moya.Task {
        switch self {
        case .updateSeconds(let second):
            let params: [String: Any] = ["alarmOffMissionDefaultDuration": second]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .updateTheme(let theme):
            let params: [String: Any] = ["theme": theme]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .updateVoice(let voice):
            let params: [String: Any] = ["briefingVoiceDefaultType": voice]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .smartVoice(let smartvoice):
            let params: [String: Any] = ["smartBriefing": smartvoice]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
        
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"
                ]
    }
}
