import SwiftUI
import Combine
import Foundation
import Moya

class AlarmViewModel: ObservableObject {
    
    @Published var alarms: [Alarm] = []
    @Published var isLoading: Bool = false
    
    private let localKey = "LOCAL_ALARMS_KEY"
    
    init() {
        // 1. 로컬 데이터 로드
        loadAlarmsFromLocal()
        
        // 🚨 [수정] 컴파일 에러 해결: Moya.Task와 충돌 방지
        // Task { ... } -> _Concurrency.Task { ... } 로 변경
        _Concurrency.Task {
            await syncAlarmKit(alarms: self.alarms)
        }
        
        // 3. 서버 동기화
        fetchAlarms()
    }
    
    // MARK: - READ (하이브리드)
    func fetchAlarms() {
        isLoading = true
        
        if !MainAPIClient<AlarmEndpoint>().isLoggedIn {
            print("📴 [Offline] 로그인 상태가 아니므로 로컬 데이터만 사용합니다.")
            isLoading = false
            return
        }
        
        print("📡 [Server] 알람 목록 동기화 시도...")
        AlarmService.shared.fetchMyAlarms { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let dtos):
                    let fetchedAlarms = dtos.map { Alarm(from: $0) }
                    self.alarms = fetchedAlarms
                    self.saveAlarmsToLocal()
                    print("✅ [Server] 동기화 완료 (\(fetchedAlarms.count)개)")
                    
                    // 🚨 [수정] _Concurrency.Task 사용
                    _Concurrency.Task {
                        await self.syncAlarmKit(alarms: self.alarms)
                    }
                    
                case .failure(let error):
                    print("⚠️ [Server] 동기화 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - CREATE (오프라인 퍼스트)
    func addAlarm(_ newAlarm: Alarm) {
        DispatchQueue.main.async {
            self.alarms.append(newAlarm)
            self.saveAlarmsToLocal()
            
            // 🚨 [수정] _Concurrency.Task 사용
            _Concurrency.Task {
                try? await AlarmKitManager.shared.scheduleAlarm(from: newAlarm)
            }
            
            if MainAPIClient<AlarmEndpoint>().isLoggedIn {
                AlarmService.shared.createAlarm(params: newAlarm.toDictionary()) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        if case .success(let dto) = result {
                            if let index = self.alarms.firstIndex(where: { $0.id == newAlarm.id }) {
                                self.alarms[index].serverId = dto.alarmId
                                self.saveAlarmsToLocal()
                                print("✅ [Server] ID 발급 완료: \(dto.alarmId)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UPDATE (오프라인 퍼스트)
    func updateAlarm(_ updatedAlarm: Alarm) {
        DispatchQueue.main.async {
            // 1. 로컬 데이터 및 AlarmKit 업데이트 (기존 코드 유지)
            if let index = self.alarms.firstIndex(where: { $0.id == updatedAlarm.id }) {
                self.alarms[index] = updatedAlarm
                self.saveAlarmsToLocal()
            }
            
            _Concurrency.Task {
                try? await AlarmKitManager.shared.scheduleAlarm(from: updatedAlarm)
            }
            
            // 2. 서버 업데이트 (기본 정보 + 미션 정보)
            if let serverId = updatedAlarm.serverId, MainAPIClient<AlarmEndpoint>().isLoggedIn {
                
                print("📡 [Server] 알람 업데이트 요청: ID \(serverId)")
                let params = updatedAlarm.toDictionary()
                
                // A. 기본 정보(시간, 요일, 라벨, 사운드 등) 수정
                // ✅ [수정] 에러 확인을 위한 로그 추가
                AlarmService.shared.updateAlarm(alarmId: serverId, params: params) { result in
                    switch result {
                    case .success(let dto):
                        print("✅ [Server] 알람 기본 정보 수정 완료. 사운드: \(dto.soundType)")
                    case .failure(let error):
                        print("❌ [Server] 알람 기본 정보 수정 실패: \(error)")
                    }
                }
                
                // ✅ B. [추가] 미션 설정 수정 API 호출
                // AlarmDTO.toDictionary 로직을 참고하여 미션 파라미터 생성
                var serverMissionType = "MATH"
                var walkGoalMeter = 0
                var questionCount = 1
                
                switch updatedAlarm.missionType {
                case "계산":
                    serverMissionType = "MATH"
                case "받아쓰기":
                    serverMissionType = "TYPING"
                case "운동":
                    serverMissionType = "WALK"
                    walkGoalMeter = 50 // 기본값 또는 알람 객체에 저장된 값 사용
                case "OX":
                    serverMissionType = "OX_QUIZ"
                default:
                    serverMissionType = "MATH"
                }
                
                let savedDifficulty = UserDefaults.standard.string(forKey: "MISSION_DIFFICULTY") ?? "MEDIUM"
                
                var serverDifficulty = "NORMAL"
                
                switch savedDifficulty {
                case "LOW":
                    serverDifficulty = "EASY"
                case "MEDIUM":
                    serverDifficulty = "MEDIUM"
                case "HIGH":
                    serverDifficulty = "HARD"
                default:
                    serverDifficulty = "MEDIUM"
                }
                
                if (serverMissionType == "OX_QUIZ" || serverMissionType == "TYPING") && serverDifficulty == "HARD" {
                    serverDifficulty = "MEDIUM"
                }
                
                
                let missionParams: [String: Any] = [
                    "missionType": serverMissionType,
                    "difficulty": serverDifficulty,
                    "walkGoalMeter": walkGoalMeter,
                    "questionCount": questionCount
                ]
                
                print("📡 [Server] 미션 변경 요청: \(serverMissionType) (난이도: \(savedDifficulty))")
                
                AlarmService.shared.updateMissionSettings(alarmId: serverId, params: missionParams) { result in
                    switch result {
                    case .success:
                        print("✅ [Server] 미션 수정 완료")
                    case .failure(let error):
                        print("⚠️ [Server] 미션 수정 실패: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - DELETE
    func deleteAlarm(id: UUID) {
        guard let alarmToDelete = alarms.first(where: { $0.id == id }) else { return }
        
        if let index = self.alarms.firstIndex(where: { $0.id == id }) {
            self.alarms.remove(at: index)
            self.saveAlarmsToLocal()
        }
        
        // 🚨 [수정] _Concurrency.Task 사용
        _Concurrency.Task {
            await AlarmKitManager.shared.removeAlarm(id: id)
        }
        
        if let serverId = alarmToDelete.serverId, MainAPIClient<AlarmEndpoint>().isLoggedIn {
            AlarmService.shared.deleteAlarm(alarmId: serverId) { _ in }
        }
    }
    
    // MARK: - TOGGLE
    func toggleAlarmState(alarm: Alarm, isOn: Bool) {
        if let index = self.alarms.firstIndex(where: { $0.id == alarm.id }) {
            self.alarms[index].isEnabled = isOn
            self.saveAlarmsToLocal()
            
            let updatedAlarm = self.alarms[index]
            
            // 🚨 [수정] _Concurrency.Task 사용
            _Concurrency.Task {
                if isOn {
                    try? await AlarmKitManager.shared.scheduleAlarm(from: updatedAlarm)
                } else {
                    await AlarmKitManager.shared.removeAlarm(id: updatedAlarm.id)
                }
            }
            
            if let serverId = updatedAlarm.serverId, MainAPIClient<AlarmEndpoint>().isLoggedIn {
                AlarmService.shared.toggleAlarm(alarmId: serverId) { _ in }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func syncAlarmKit(alarms: [Alarm]) async {
        print("🔄 [System] 시스템 알람 일괄 동기화")
        
        // 서버에서 다시 받아와서 UUID가 바뀌기 전에, 옛날에 예약된 모든 알림을 완전히 지워버립니다.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        for alarm in alarms where alarm.isEnabled {
            try? await AlarmKitManager.shared.scheduleAlarm(from: alarm)
        }
    }
    
    private func saveAlarmsToLocal() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: localKey)
        }
    }
    
    private func loadAlarmsFromLocal() {
        if let savedData = UserDefaults.standard.data(forKey: localKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: savedData) {
            self.alarms = decoded
            print("📂 [Local] 로컬 알람 로드 완료 (\(decoded.count)개)")
        }
    }
}
