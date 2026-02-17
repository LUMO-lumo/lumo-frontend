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
    /// 주의: Encodable 프로토콜을 직접 사용하는 경우, Swift 버전에 따라 'any Encodable'로 명시해야 할 수도 있습니다.
    case submitMission(alarmId: Int, request: Encodable)
    
    /// 3. 알람 해제 (POST / Path + JSON Body)
    case dismissAlarm(alarmId: Int, request: DismissAlarmRequest)
}

extension MissionTarget: @MainActor APITargetType {
    
    var baseURL: URL {
        // AppConfig.baseURL이 확실하다고 가정합니다.
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
        do {
            // try를 사용하여 세션을 불러옵니다.
            let userInfo = try KeychainManager.standard.loadSession(for: "userSession")
            
            if let accessToken = userInfo.accessToken {
                // 3. 헤더에 토큰 추가 (Bearer + 공백 + 토큰)
                header["Authorization"] = "Bearer \(accessToken)"
                
                // 디버깅용 로그 (배포 시 주석 처리 권장)
                print("🔑 [MissionTarget] 헤더에 토큰 추가됨")
            } else {
                print("⚠️ [MissionTarget] 세션은 있으나 Access Token이 없습니다.")
            }
            
        } catch {
            // 4. 에러 발생 시 (로그인이 안 되어 있거나 키체인 오류)
            // 401 Unauthorized 발생 시 로그인 화면으로 이동하는 로직은 보통 API 호출부에서 처리합니다.
            print("ℹ️ [MissionTarget] 토큰 로드 실패 (비로그인 상태): \(error)")
        }
        
        return header
    }
}
