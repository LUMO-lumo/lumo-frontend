//
//  AlarmEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/8/26.
//

import Foundation

import Alamofire
import Moya

enum AlarmEndpoint: @MainActor MainEndpoint {
    
    // MARK: - Cases
    
    // 알람 CRUD
    case fetchAlarmDetail(alarmId: Int)
    case updateAlarm(alarmId: Int, body: [String: Any])
    case deleteAlarm(alarmId: Int)
    case fetchMyAlarms
    case createAlarm(body: [String: Any])
    
    // 상태 제어
    case toggleAlarm(alarmId: Int)
    case recordAlarmTrigger(alarmId: Int)
    
    // 스누즈 및 반복 설정
    case fetchSnoozeSettings(alarmId: Int)
    case updateSnoozeSettings(alarmId: Int, body: [String: Any])
    case toggleSnooze(alarmId: Int)
    case fetchRepeatDays(alarmId: Int)
    case updateRepeatDays(alarmId: Int, body: [String: Any])
    
    // 미션 관련
    case fetchMissionSettings(alarmId: Int)
    case updateMissionSettings(alarmId: Int, body: [String: Any])
    case startMission(alarmId: Int)
    case updateWalkMissionDistance(alarmId: Int, body: [String: Any])
    case submitMissionAnswer(alarmId: Int, body: [String: Any])
    
    // 로그 및 사운드
    case fetchAlarmLogs(alarmId: Int)
    case fetchMyAlarmHistory
    case fetchMyMissionHistory
    case fetchAlarmSounds
    
    // MARK: - Moya Path
    
    var path: String {
        switch self {
        case .fetchAlarmDetail(let id),
            .updateAlarm(let id, _),
            .deleteAlarm(let id):
            return "/api/alarms/\(id)"
            
        case .fetchMyAlarms,
            .createAlarm:
            return "/api/alarms"
            
        case .toggleAlarm(let id):
            return "/api/alarms/\(id)/toggle"
            
        case .recordAlarmTrigger(let id):
            return "/api/alarms/\(id)/trigger"
            
        case .fetchSnoozeSettings(let id),
            .updateSnoozeSettings(let id, _):
            return "/api/alarms/\(id)/snooze"
            
        case .toggleSnooze(let id):
            return "/api/alarms/\(id)/snooze/toggle"
            
        case .fetchRepeatDays(let id),
            .updateRepeatDays(let id, _):
            return "/api/alarms/\(id)/repeat-days"
            
        case .fetchMissionSettings(let id),
            .updateMissionSettings(let id, _):
            return "/api/alarms/\(id)/mission"
            
        case .startMission(let id):
            return "/api/alarms/\(id)/missions/start"
            
        case .updateWalkMissionDistance(let id, _):
            return "/api/alarms/\(id)/missions/walk"
            
        case .submitMissionAnswer(let id, _):
            return "/api/alarms/\(id)/missions/submit"
            
        case .fetchAlarmLogs(let id):
            return "/api/alarms/\(id)/logs"
            
        case .fetchMyAlarmHistory:
            return "/api/alarms/members/me/alarm-logs"
            
        case .fetchMyMissionHistory:
            return "/api/alarms/members/me/mission-history"
            
        case .fetchAlarmSounds:
            return "/api/alarms/sounds"
        }
    }
    
    // MARK: - Moya Method 각각의 메서드별로 연결
    
    var method: Moya.Method {
        switch self {
        case .fetchAlarmDetail,
            .fetchMyAlarms,
            .fetchSnoozeSettings,
            .fetchRepeatDays,
            .fetchMissionSettings,
            .fetchAlarmLogs,
            .fetchMyAlarmHistory,
            .fetchMyMissionHistory,
            .fetchAlarmSounds:
            return .get
            
        case .updateAlarm,
            .updateSnoozeSettings,
            .updateRepeatDays,
            .updateMissionSettings:
            return .put
            
        case .createAlarm,
            .recordAlarmTrigger,
            .startMission,
            .updateWalkMissionDistance,
            .submitMissionAnswer:
            return .post
            
        case .deleteAlarm:
            return .delete
            
        case .toggleAlarm,
            .toggleSnooze:
            return .patch
        }
    }
    
    // Headers를 명시적으로 지정하여 Content-Type 누락 방지
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    // MARK: - Moya Task (인코딩 방식 변경)
    
    var task: Moya.Task {
        switch self {
        // SONEncoding.default 대신 직접 Data로 변환하여 전송 (.requestData)
        // 이렇게 하면 Alamofire가 중간에서 데이터를 건드리지 않고, 우리가 만든 JSON 그대로 서버에 날아갑니다.
        case .createAlarm(let body),
            .updateAlarm(_, let body),
            .updateSnoozeSettings(_, let body),
            .updateRepeatDays(_, let body),
            .updateMissionSettings(_, let body),
            .updateWalkMissionDistance(_, let body),
            .submitMissionAnswer(_, let body):
            
            // 🚨 [추가] 서버 전송 전 데이터 클렌징 (Data Sanitization)
            var cleanBody = body
            
            // 1. alarmTime 포맷 강제 수정 (HH:mm:ss -> HH:mm)
            // DTO에서 초 단위가 포함되어 넘어오더라도, 여기서 잘라내어 서버가 좋아하는 HH:mm 형식으로 맞춥니다.
            if let timeString = cleanBody["alarmTime"] as? String, timeString.count > 5 {
                let timeParts = timeString.split(separator: ":")
                if timeParts.count >= 2 {
                    let fixedTime = "\(timeParts[0]):\(timeParts[1])"
                    cleanBody["alarmTime"] = fixedTime
                }
            }
            
            // 딕셔너리를 JSON 데이터로 직접 변환
            do {
                // 수정된 cleanBody를 사용하여 JSON 생성
                let jsonData = try JSONSerialization.data(
                    withJSONObject: cleanBody,
                    options: []
                )
                // 디버깅용: 실제로 전송되는 데이터 확인
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📦 [Client Encoding] Final JSON: \(jsonString)")
                }
                return .requestData(jsonData)
            } catch {
                print("❌ JSON Encoding Failed: \(error)")
                // 실패 시 백업으로 기존 방식 사용
                return .requestParameters(
                    parameters: body,
                    encoding: JSONEncoding.default
                )
            }
            
        default:
            return .requestPlain
        }
    }
}
