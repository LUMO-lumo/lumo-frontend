import SwiftUI
import Combine
import Foundation
import Moya

class AlarmViewModel: ObservableObject {
    
    @Published var alarms: [Alarm] = []
    
    init() {
        fetchAlarms()
    }
    
    // MARK: - READ (서버에서 목록 조회)
    func fetchAlarms() {
        print("📡 서버에서 알람 목록 조회 요청...")
        
        AlarmService.shared.fetchMyAlarms { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let dtos):
                // DTO(서버 데이터) -> Alarm(앱 모델) 변환
                let fetchedAlarms = dtos.map { Alarm(from: $0) }
                
                // [수정] Task -> _Concurrency.Task로 변경하여 Moya.Task와의 충돌 방지
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
    
    // MARK: - DELETE (서버 및 로컬 삭제)
    func firstdeleteAlarm(id: UUID) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        let alarmToDelete = alarms[index]
        
        print("🗑️ 알람 삭제 요청: \(alarmToDelete.label)")
        
        if let serverId = alarmToDelete.serverId {
            AlarmService.shared.deleteAlarm(alarmId: serverId) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    print("✅ 서버 알람 삭제 성공")
                    self.removeLocalAlarm(at: index, id: id)
                    
                case .failure(let error):
                    print("❌ 서버 알람 삭제 실패: \(error.localizedDescription)")
                    // 실패 시 UI 원복 등의 처리가 필요할 수 있음
                }
            }
        } else {
            print("⚠️ ServerID 없음, 로컬 삭제만 진행")
            removeLocalAlarm(at: index, id: id)
        }
    }
    
    private func removeLocalAlarm(at index: Int, id: UUID) {
        // UI 업데이트
        // [수정] Task -> _Concurrency.Task
        _Concurrency.Task { @MainActor in
            if self.alarms.indices.contains(index) {
                self.alarms.remove(at: index)
            }
        }
        
        // 시스템 알람 삭제
        // [수정] Task -> _Concurrency.Task
        _Concurrency.Task {
            await AlarmKitManager.shared.removeAlarm(id: id)
            print("🗑️ 시스템 알람 삭제 완료")
        }
    }
    
    // MARK: - UPDATE (서버 및 로컬 수정)
    func firstupdateAlarm(_ updatedAlarm: Alarm) {
        print("✏️ 알람 수정 요청: \(updatedAlarm.label)")
        
        guard let serverId = updatedAlarm.serverId else {
            print("❌ 수정 실패: ServerID가 없습니다.")
            return
        }
        
        let params = updatedAlarm.toDictionary()
        
        AlarmService.shared.updateAlarm(alarmId: serverId, params: params) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let dto):
                print("✅ 서버 알람 수정 성공")
                let newAlarmModel = Alarm(from: dto)
                
                // [수정] Task -> _Concurrency.Task
                _Concurrency.Task { @MainActor in
                    if let index = self.alarms.firstIndex(where: { $0.id == updatedAlarm.id }) {
                        self.alarms[index] = newAlarmModel
                    }
                    
                    do {
                        try await AlarmKitManager.shared.scheduleAlarm(from: newAlarmModel)
                        print("🔄 시스템 알람 갱신 성공")
                    } catch {
                        print("❌ 시스템 알람 갱신 실패: \(error)")
                    }
                }
                
            case .failure(let error):
                print("❌ 서버 알람 수정 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CREATE (생성 후 리스트 갱신)
    func addAlarm(_ newAlarm: Alarm) {
        print("➕ 새 알람 리스트 추가 요청")
        
        // [수정] Task -> _Concurrency.Task
        _Concurrency.Task { @MainActor in
            self.alarms.append(newAlarm)
            
            do {
                try await AlarmKitManager.shared.scheduleAlarm(from: newAlarm)
                print("✅ 시스템 알람 등록 성공")
            } catch {
                print("❌ 새 알람 등록 실패: \(error)")
            }
        }
    }
    
    // MARK: - Helper
    private func syncAlarmKit(alarms: [Alarm]) async {
        // 필요 시 전체 알람 동기화 로직 구현
    }
}
