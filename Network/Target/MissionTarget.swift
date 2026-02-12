//
//  MissionTarget.swift
//  Lumo
//
//  Created by 김승겸 on 2/11/26.
//

import Foundation
import Alamofire
import Moya

enum MissionTarget {
    /// 1. 미션 시작 (POST / Path)
    case startMission(alarmId: Int)
    
    /// 2. 미션 답안 제출 (POST / Path + JSON Body)
    case submitMission(alarmId: Int, request: Encodable)
    
    /// 3. 알람 해제 (POST / Path + JSON Body)
    case dismissAlarm(alarmId: Int, request: DismissAlarmRequest)
}

extension MissionTarget: @MainActor APITargetType {
    
    var baseURL: URL {
        // UserTarget과 동일한 Base URL 로직을 사용한다고 가정 (실제 프로젝트 설정에 따름)
        return URL(string: AppConfig.baseURL)!
    }
    
    // 각 API의 경로 (alarmId가 Path에 포함됨)
    var path: String {
        switch self {
        case .startMission(let alarmId):
            return "/api/alarms/\(alarmId)/missions/start"
            
        case .submitMission(let alarmId, _):
            return "/api/alarms/\(alarmId)/missions/submit"
            
        case .dismissAlarm(let alarmId, _):
            return "/api/alarms/\(alarmId)/dismiss"
        }
    }
    
    // 통신 방식
    var method: Moya.Method {
        return .post
    }
    
    // 데이터 전송 방식
    var task: Moya.Task {
        switch self {
        case .startMission:
            // Body나 Query 없이 Path만으로 호출하는 경우
            return .requestPlain
            
        case .submitMission(_, let request):
            return .requestJSONEncodable(request)
            
        case .dismissAlarm(_, let request):
            return .requestJSONEncodable(request)
        }
    }
    
    var headers: [String : String]? {
            // 1. 기본 헤더 설정
            var header = ["Content-Type": "application/json"]
            
            // 2. 키체인에서 저장된 토큰 꺼내오기
            // (LoginViewModel에서 저장할 때 썼던 키 "userSession"과 똑같아야 합니다)
            if let userInfo: UserInfo = KeychainManager.standard.loadSession(for: "userSession") {
                
                // 3. 헤더에 토큰 추가 (Bearer + 공백 + 토큰)
                header["Authorization"] = "Bearer \(userInfo.accessToken ?? "토큰 없음")"
                
                print("🔑 헤더에 토큰 추가됨: \(userInfo.accessToken ?? "토큰 없음")")
            }
            
            return header
        }
    }
