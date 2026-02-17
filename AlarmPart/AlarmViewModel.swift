import SwiftUI
import Combine
import Foundation
import Moya

class AlarmViewModel: ObservableObject {
    
    @Published var alarms: [Alarm] = []
    
    // [추가] 중복 요청 방지용 플래그
    @Published var isLoading: Bool = false
    
    init() {
        fetchAlarms()
    }
    
    // MARK: - READ (알람 목록 조회)
    func fetchAlarms() {
        print("📡 서버에서 알람 목록 조회 요청...")
        isLoading = true
        
        AlarmService.shared.fetchMyAlarms { [weak self] result in
            guard let self = self else { return }
            
            // UI 업데이트는 메인 스레드에서
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let dtos):
                    let fetchedAlarms = dtos.map { Alarm(from: $0) }
                    self.alarms = fetchedAlarms
                    print("✅ 알람 목록 로드 성공: \(fetchedAlarms.count)개")
                    
                    // AlarmKit 동기화 (비동기)
                    AsyncTask {
                        await self.syncAlarmKit(alarms: fetchedAlarms)
                    }
                    
                case .failure(let error):
                    print("❌ 알람 목록 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - DELETE (알람 삭제)
    // [수정] Index 대신 ID를 사용하여 안전하게 삭제
    func deleteAlarm(id: UUID) {
        // 1. 로컬 목록에서 해당 알람 찾기
        guard let alarmToDelete = alarms.first(where: { $0.id == id }) else {
            print("⚠️ 이미 삭제된 알람입니다.")
            return
        }
        
        print("🗑 삭제 시도: \(alarmToDelete.label), ServerID: \(String(describing: alarmToDelete.serverId))")
        
        // 2. 서버 ID가 있으면 서버 요청
        if let serverId = alarmToDelete.serverId {
            isLoading = true
            
            AlarmService.shared.deleteAlarm(alarmId: serverId) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        print("✅ 서버 알람 삭제 성공")
                        // 3. 서버 성공 시 로컬 및 시스템 알람 삭제
                        self.removeLocalAndSystemAlarm(id: id)
                        
                    case .failure(let error):
                        print("❌ 서버 알람 삭제 실패: \(error.localizedDescription)")
                        // 실패 시 사용자에게 알림을 주거나, 목록을 다시 불러오는 것이 좋음
                        // self.fetchAlarms()
                    }
                }
            }
        } else {
            // 서버 ID가 없는 로컬 알람이라면 즉시 삭제
            print("⚠️ ServerID가 없어서 로컬에서만 삭제합니다.")
            removeLocalAndSystemAlarm(id: id)
        }
    }
    
    // [수정] 안전한 로컬/시스템 알람 삭제 헬퍼
    private func removeLocalAndSystemAlarm(id: UUID) {
        // 1. UI 목록에서 ID로 찾아서 삭제 (Index 사용 X)
        if let index = self.alarms.firstIndex(where: { $0.id == id }) {
            self.alarms.remove(at: index)
        }
        
        // 2. 시스템 알람(AlarmKit)에서도 삭제
        AsyncTask {
            await AlarmKitManager.shared.removeAlarm(id: id)
        }
    }
    
    // MARK: - UPDATE (알람 수정)
    func updateAlarm(_ updatedAlarm: Alarm) {
        guard let serverId = updatedAlarm.serverId else { return }
        
        // [방어] 로딩 중이면 요청 무시 (연타 방지)
        if isLoading { return }
        isLoading = true
        
        let params = updatedAlarm.toDictionary()
        
        AlarmService.shared.updateAlarm(alarmId: serverId, params: params) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let dto):
                    let newAlarmModel = Alarm(from: dto)
                    
                    // 1. 로컬 목록 갱신 (ID로 찾아서 교체)
                    if let index = self.alarms.firstIndex(where: { $0.id == newAlarmModel.id }) {
                        self.alarms[index] = newAlarmModel
                    }
                    
                    // 2. 시스템 알람 재설정
                    AsyncTask {
                        do {
                            try await AlarmKitManager.shared.scheduleAlarm(from: newAlarmModel)
                            print("✅ 시스템 알람 갱신 완료")
                        } catch {
                            print("❌ 시스템 알람 갱신 실패: \(error)")
                        }
                    }
                    
                case .failure(let error):
                    print("❌ 서버 알람 수정 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - TOGGLE (ON/OFF 스위치)
    func toggleAlarmState(alarm: Alarm, isOn: Bool) {
        guard let serverId = alarm.serverId else { return }
        print("🔘 알람 ON/OFF 토글 요청: \(alarm.label) -> \(isOn ? "ON" : "OFF")")
        
        // Optimistic UI: 서버 응답 기다리지 않고 UI 먼저 반영 (반응성 향상)
        if let index = self.alarms.firstIndex(where: { $0.id == alarm.id }) {
            self.alarms[index].isEnabled = isOn
        }
        
        AlarmService.shared.toggleAlarm(alarmId: serverId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let dto):
                    print("✅ 서버 알람 토글 동기화 성공 (상태: \(dto.isEnabled))")
                    
                    // 시스템 알람 스케줄링 동기화
                    AsyncTask {
                        if dto.isEnabled {
                            // ON: 스케줄링 등록
                            // (주의: dto에는 일부 정보가 없을 수 있으니 기존 alarm 정보와 합쳐서 사용 권장)
                            var updatedAlarm = alarm
                            updatedAlarm.isEnabled = true
                            try? await AlarmKitManager.shared.scheduleAlarm(from: updatedAlarm)
                        } else {
                            // OFF: 스케줄링 해제
                            await AlarmKitManager.shared.removeAlarm(id: alarm.id)
                        }
                    }
                    
                case .failure(let error):
                    print("❌ 서버 알람 토글 실패: \(error.localizedDescription)")
                    // 실패 시 롤백 (원래 상태로 되돌림)
                    if let index = self.alarms.firstIndex(where: { $0.id == alarm.id }) {
                        self.alarms[index].isEnabled = !isOn
                    }
                }
            }
        }
    }
    
    // MARK: - CREATE (새 알람 추가)
    // 보통 서버 생성이 먼저 이루어지고, 그 결과를 받아서 addAlarm을 호출하는 흐름이 일반적입니다.
    // 여기서는 로컬에 먼저 추가하는 로직으로 보입니다.
    func addAlarm(_ newAlarm: Alarm) {
        DispatchQueue.main.async {
            self.alarms.append(newAlarm)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchAlarms()
            }
            
            AsyncTask {
                do {
                    try await AlarmKitManager.shared.scheduleAlarm(from: newAlarm)
                    print("✅ 새 알람 시스템 등록 완료")
                } catch {
                    print("❌ 새 알람 등록 실패: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper
    private func syncAlarmKit(alarms: [Alarm]) async {
        // 서버에서 받아온 목록으로 시스템 알람을 싹 동기화하는 로직 (구현 필요 시 작성)
        // 예: 기존 시스템 알람 다 지우고, 받아온 목록 중 isEnabled인 것만 다시 등록
    }
}
