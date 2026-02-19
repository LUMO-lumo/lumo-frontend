//
//  SettingTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation

import Alamofire
import Moya

enum SettingTarget {
    case updateSeconds(second: Int)
    case updateTheme(theme: String)
    case updateVoice(voice: String)
    case smartVoice(smartvoice: Bool)
    case updateMissionLevel(level: String)
}

extension SettingTarget: @MainActor APITarget {
    
    var path: String {
        return "/api/setting"
    }
    
    var method: Moya.Method {
        return .patch
    }

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
            
        case .updateMissionLevel(let level):
            let params: [String: Any] = ["alarmOffMissionDefaultLevel": level]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String: String]? {
        // 1. 기본 헤더 설정
        var header = ["Content-Type": "application/json"]
        
        // 2. 키체인에서 저장된 토큰 꺼내오기
        do {
            // try를 사용하여 값을 가져옵니다. 실패하면 catch 블록으로 이동합니다.
            let userInfo = try KeychainManager.standard.loadSession(for: "userSession")
            
            if let accessToken = userInfo.accessToken {
                // 3. 헤더에 토큰 추가
                header["Authorization"] = "Bearer \(accessToken)"
                print("🔑 헤더에 토큰 추가됨")
            } else {
                print("⚠️ 토큰이 존재하지 않습니다.")
            }
            
        } catch {
            // 4. 에러 발생 시 (로그인이 안 되어 있거나 키체인 오류)
            // 여기서는 토큰 없이 헤더를 반환하거나, 로그를 남깁니다.
            print("⚠️ 토큰 로드 실패: \(error)")
        }
        
        return header
    }
}
