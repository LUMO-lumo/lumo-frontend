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
    
    // [변경] MainAPIClient 사용
    private let client = MainAPIClient<AlarmEndpoint>()
    
    private init() {}
    
    // MARK: - Alarm API Methods
    
    func fetchMyAlarms(completion: @escaping (Result<[AlarmDTO], MainAPIError>) -> Void) {
        client.request(.fetchMyAlarms, completion: completion)
    }
    
    func fetchAlarmDetail(alarmId: Int, completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.fetchAlarmDetail(alarmId: alarmId), completion: completion)
    }
    
    func createAlarm(params: [String: Any], completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.createAlarm(body: params), completion: completion)
    }
    
    func updateAlarm(alarmId: Int, params: [String: Any], completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.updateAlarm(alarmId: alarmId, body: params), completion: completion)
    }
    
    // ✅ [수정] 삭제 결과가 null일 수 있으므로 String? 타입 사용
    func deleteAlarm(alarmId: Int, completion: @escaping (Result<String?, MainAPIError>) -> Void) {
        client.request(.deleteAlarm(alarmId: alarmId), completion: completion)
    }
    
    func toggleAlarm(alarmId: Int, completion: @escaping (Result<AlarmDTO, MainAPIError>) -> Void) {
        client.request(.toggleAlarm(alarmId: alarmId), completion: completion)
    }
    
    // MARK: - Missions
    
    func startMission(alarmId: Int, completion: @escaping (Result<[MissionContentDTO], MainAPIError>) -> Void) {
        client.request(.startMission(alarmId: alarmId), completion: completion)
    }
    
    func submitMissionAnswer(alarmId: Int, params: [String: Any], completion: @escaping (Result<MissionSubmitResultDTO, MainAPIError>) -> Void) {
        client.request(.submitMissionAnswer(alarmId: alarmId, body: params), completion: completion)
    }
    
    func updateWalkMissionDistance(alarmId: Int, params: [String: Any], completion: @escaping (Result<WalkMissionResultDTO, MainAPIError>) -> Void) {
        client.request(.updateWalkMissionDistance(alarmId: alarmId, body: params), completion: completion)
    }
    
    // ✅ [복구] 미션 설정 수정
    func updateMissionSettings(alarmId: Int, params: [String: Any], completion: @escaping (Result<MissionSettingDTO, MainAPIError>) -> Void) {
        client.request(.updateMissionSettings(alarmId: alarmId, body: params), completion: completion)
    }
    
    // MARK: - Logs
    
    func recordAlarmTrigger(alarmId: Int, completion: @escaping (Result<AlarmLogDTO, MainAPIError>) -> Void) {
        client.request(.recordAlarmTrigger(alarmId: alarmId), completion: completion)
    }
    
    func fetchMyAlarmHistory(completion: @escaping (Result<[AlarmLogDTO], MainAPIError>) -> Void) {
        client.request(.fetchMyAlarmHistory, completion: completion)
    }
    
    // MARK: - Settings
    
    func fetchSnoozeSettings(alarmId: Int, completion: @escaping (Result<SnoozeSettingDTO, MainAPIError>) -> Void) {
        client.request(.fetchSnoozeSettings(alarmId: alarmId), completion: completion)
    }
    
    func updateSnoozeSettings(alarmId: Int, params: [String: Any], completion: @escaping (Result<SnoozeSettingDTO, MainAPIError>) -> Void) {
        client.request(.updateSnoozeSettings(alarmId: alarmId, body: params), completion: completion)
    }
}
