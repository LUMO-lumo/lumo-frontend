//
//  SettingTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
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

// ✅ [수정 1] @MainActor 추가: 메인 스레드 격리 문제 해결
extension SettingTarget: @MainActor APITargetType {
    
    var path: String { return "/api/setting" }
    
    var method: Moya.Method { return .patch }

    // ✅ [수정 2] Moya.Task 명시: Swift Task와 이름 충돌 방지
    var task: Moya.Task {
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
}
