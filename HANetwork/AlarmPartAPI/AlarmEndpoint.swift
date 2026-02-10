//
//  AlarmEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/8/26.
//

import Foundation
import Moya
import Alamofire

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
        case .fetchAlarmDetail(let id), .updateAlarm(let id, _), .deleteAlarm(let id):
            return "/api/alarms/\(id)"
        case .fetchMyAlarms, .createAlarm:
            return "/api/alarms"
        case .toggleAlarm(let id):
            return "/api/alarms/\(id)/toggle"
        case .recordAlarmTrigger(let id):
            return "/api/alarms/\(id)/trigger"
        case .fetchSnoozeSettings(let id), .updateSnoozeSettings(let id, _):
            return "/api/alarms/\(id)/snooze"
        case .toggleSnooze(let id):
            return "/api/alarms/\(id)/snooze/toggle"
        case .fetchRepeatDays(let id), .updateRepeatDays(let id, _):
            return "/api/alarms/\(id)/repeat-days"
        case .fetchMissionSettings(let id), .updateMissionSettings(let id, _):
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
        case .fetchAlarmDetail, .fetchMyAlarms, .fetchSnoozeSettings, .fetchRepeatDays,
             .fetchMissionSettings, .fetchAlarmLogs, .fetchMyAlarmHistory, .fetchMyMissionHistory, .fetchAlarmSounds:
            return .get
        case .updateAlarm, .updateSnoozeSettings, .updateRepeatDays, .updateMissionSettings:
            return .put
        case .createAlarm, .recordAlarmTrigger, .startMission, .updateWalkMissionDistance, .submitMissionAnswer:
            return .post
        case .deleteAlarm:
            return .delete
        case .toggleAlarm, .toggleSnooze:
            return .patch
        }
    }

    // MARK: - Moya Task
    var task: Moya.Task {
        switch self {
        case .updateAlarm(_, let body),
             .createAlarm(let body),
             .updateSnoozeSettings(_, let body),
             .updateRepeatDays(_, let body),
             .updateMissionSettings(_, let body),
             .updateWalkMissionDistance(_, let body),
             .submitMissionAnswer(_, let body):
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        default:
            return .requestPlain
        }
    }
}
