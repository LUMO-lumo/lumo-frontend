import SwiftUI
import Combine
import Foundation
import Moya

class AlarmViewModel: ObservableObject {
    
    @Published var alarms: [Alarm] = []
    
    init() {
        fetchAlarms()
    }
    
    // MARK: - READ
    func fetchAlarms() {
        print("📡 서버에서 알람 목록 조회 요청...")
        AlarmService.shared.fetchMyAlarms { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let dtos):
                let fetchedAlarms = dtos.map { Alarm(from: $0) }
                _Concurrency.Task { @MainActor in
                    self.alarms = fetchedAlarms
                    print("✅ 알람 목록 로드 성공: \(fetchedAlarms.count)개")
                    await self.syncAlarmKit(alarms: fetchedAlarms)
                }
            case .failure(let error):
                print("❌ 알람 목록 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - DELETE
    func firstdeleteAlarm(id: UUID) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        let alarmToDelete = alarms[index]
        
        if let serverId = alarmToDelete.serverId {
            AlarmService.shared.deleteAlarm(alarmId: serverId) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    print("✅ 서버 알람 삭제 성공")
                    self.removeLocalAlarm(at: index, id: id)
                case .failure(let error):
                    print("❌ 서버 알람 삭제 실패: \(error.localizedDescription)")
                }
            }
        } else {
            removeLocalAlarm(at: index, id: id)
        }
    }
    
    private func removeLocalAlarm(at index: Int, id: UUID) {
        _Concurrency.Task { @MainActor in
            if self.alarms.indices.contains(index) { self.alarms.remove(at: index) }
        }
        _Concurrency.Task { await AlarmKitManager.shared.removeAlarm(id: id) }
    }
    
    // MARK: - UPDATE (전체 수정)
    func firstupdateAlarm(_ updatedAlarm: Alarm) {
        guard let serverId = updatedAlarm.serverId else { return }
        let params = updatedAlarm.toDictionary()
        
        AlarmService.shared.updateAlarm(alarmId: serverId, params: params) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let dto):
                let newAlarmModel = Alarm(from: dto)
                _Concurrency.Task { @MainActor in
                    if let index = self.alarms.firstIndex(where: { $0.id == updatedAlarm.id }) {
                        self.alarms[index] = newAlarmModel
                    }
                    do {
                        try await AlarmKitManager.shared.scheduleAlarm(from: newAlarmModel)
                    } catch {
                        print("❌ 시스템 알람 갱신 실패: \(error)")
                    }
                }
            case .failure(let error):
                print("❌ 서버 알람 수정 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // ✅ [추가] 상태 토글 전용 함수 (PATCH API 사용)
    func toggleAlarmState(alarm: Alarm, isOn: Bool) {
        guard let serverId = alarm.serverId else { return }
        print("🔘 알람 ON/OFF 토글 요청: \(alarm.label) -> \(isOn ? "ON" : "OFF")")
        
        // 1. 서버에 토글 상태 전송 (PATCH API)
        AlarmService.shared.toggleAlarm(alarmId: serverId) { [weak self] result in
            switch result {
            case .success(let dto):
                print("✅ 서버 알람 토글 성공 (상태: \(dto.isEnabled))")
                
                // 2. 서버 통신 성공 후 로컬 알람 스케줄링 관리
                _Concurrency.Task { @MainActor in
                    if dto.isEnabled {
                        // ON일 경우 새로 스케줄링 등록
                        var updatedAlarm = alarm
                        updatedAlarm.isEnabled = true
                        try? await AlarmKitManager.shared.scheduleAlarm(from: updatedAlarm)
                    } else {
                        // OFF일 경우 시스템 알림에서 해제
                        await AlarmKitManager.shared.removeAlarm(id: alarm.id)
                    }
                }
            case .failure(let error):
                print("❌ 서버 알람 토글 실패: \(error.localizedDescription)")
                // 통신 실패 시 UI 스위치를 다시 원래대로 되돌리는 롤백 로직을 추가할 수도 있습니다.
            }
        }
    }
    
    // MARK: - CREATE
    func addAlarm(_ newAlarm: Alarm) {
        _Concurrency.Task { @MainActor in
            self.alarms.append(newAlarm)
            do {
                try await AlarmKitManager.shared.scheduleAlarm(from: newAlarm)
            } catch {
                print("❌ 새 알람 등록 실패: \(error)")
            }
        }
    }
    
    // MARK: - Helper
    private func syncAlarmKit(alarms: [Alarm]) async {}
}
