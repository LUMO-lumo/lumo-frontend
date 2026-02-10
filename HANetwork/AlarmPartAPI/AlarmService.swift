//
//  AlarmService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire

class AlarmService {
    static let shared = AlarmService()
    
    // [변경] MoyaProvider 직접 사용 대신 MainAPIClient 래퍼 클래스 사용
    private let client = MainAPIClient<AlarmEndpoint>()
    
    private init() {}
    
    // MARK: - Alarm API Methods (Closure 방식)
    
    // 내 알람 목록 조회
    func fetchMyAlarms(completion: @escaping (Result<[AlarmDTO], MainAPIError>) -> Void) {
        client.request(.fetchMyAlarms, completion: completion)
    }
    
    // 알람 상세 조회
    func fetchAlarmDetail(alarmId: Int, completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.fetchAlarmDetail(alarmId: alarmId), completion: completion)
    }
    
    // 알람 생성
    func createAlarm(params: [String: Any], completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.createAlarm(body: params), completion: completion)
    }
    
    // 알람 수정
    func updateAlarm(alarmId: Int, params: [String: Any], completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.updateAlarm(alarmId: alarmId, body: params), completion: completion)
    }
    
    // 알람 삭제
    func deleteAlarm(alarmId: Int, completion: @escaping (Result<String, MainAPIError>) -> Void) {
        client.request(.deleteAlarm(alarmId: alarmId), completion: completion)
    }
    
    // 알람 ON/OFF 토글
    func toggleAlarm(alarmId: Int, completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.toggleAlarm(alarmId: alarmId), completion: completion)
    }
    
    // MARK: - Missions
    
    // 미션 시작
    func startMission(alarmId: Int, completion: @escaping (Result<[MissionContentDTO], MainAPIError>) -> Void) {
        client.request(.startMission(alarmId: alarmId), completion: completion)
    }
    
    // 미션 답안 제출
    func submitMissionAnswer(alarmId: Int, params: [String: Any], completion: @escaping (Result<MissionSubmitResultDTO, MainAPIError>) -> Void) {
        client.request(.submitMissionAnswer(alarmId: alarmId, body: params), completion: completion)
    }
    
    // 걷기 미션 거리 업데이트
    func updateWalkMissionDistance(alarmId: Int, params: [String: Any], completion: @escaping (Result<WalkMissionResultDTO, MainAPIError>) -> Void) {
        client.request(.updateWalkMissionDistance(alarmId: alarmId, body: params), completion: completion)
    }
    
    // MARK: - Logs
    
    // 알람 울림 기록
    func recordAlarmTrigger(alarmId: Int, completion: @escaping (Result<AlarmLogDTO, MainAPIError>) -> Void) {
        client.request(.recordAlarmTrigger(alarmId: alarmId), completion: completion)
    }
    
    // 내 알람 울림 기록 조회
    func fetchMyAlarmHistory(completion: @escaping (Result<[AlarmLogDTO], MainAPIError>) -> Void) {
        client.request(.fetchMyAlarmHistory, completion: completion)
    }
    
    // MARK: - Settings (Snooze & Repeat)
    
    func fetchSnoozeSettings(alarmId: Int, completion: @escaping (Result<SnoozeSettingDTO, MainAPIError>) -> Void) {
        client.request(.fetchSnoozeSettings(alarmId: alarmId), completion: completion)
    }
    
    func updateSnoozeSettings(alarmId: Int, params: [String: Any], completion: @escaping (Result<SnoozeSettingDTO, MainAPIError>) -> Void) {
        client.request(.updateSnoozeSettings(alarmId: alarmId, body: params), completion: completion)
    }
}
