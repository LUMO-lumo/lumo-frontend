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
                AsyncTask { @MainActor in
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
                    self.removeLocalAlarm(id: id)
                case .failure(let error):
                    print("❌ 서버 알람 삭제 실패: \(error.localizedDescription)")
                }
            }
        } else {
            removeLocalAlarm(id: id)
        }
    }
    
    private func removeLocalAlarm(id: UUID) {
            AsyncTask { @MainActor in
                // ⚠️ 여기서 다시 검색합니다. 배열이 변했어도 ID로 찾으면 안전합니다.
                if let index = self.alarms.firstIndex(where: { $0.id == id }) {
                    self.alarms.remove(at: index)
                    print("🗑️ 로컬 리스트 삭제 완료 (Index: \(index))")
                } else {
                    print("⚠️ 로컬 리스트에서 알람을 찾을 수 없음 (이미 삭제됨)")
                }
                
                // 시스템 알람 해제
                await AlarmKitManager.shared.removeAlarm(id: id)
            }
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
                AsyncTask { @MainActor in
                                    // 여기서도 ID로 다시 인덱스를 찾아서 업데이트해야 안전합니다.
                                    if let index = self.alarms.firstIndex(where: { $0.serverId == serverId }) {
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
        AsyncTask { @MainActor in
                    // 1. 리스트에 먼저 추가 (UI 반응성)
                    self.alarms.append(newAlarm)
                    
                    // 🚨 [핵심 수정] AlarmKit에 보낼 때는 '안전한 복사본'을 만듭니다.
                    var safeAlarm = newAlarm
                    
                    // "기본음" 같은 한글 이름이나 확장자가 없는 파일명은 에러(Code=1)를 유발합니다.
                    // 일단 nil로 설정하면 아이폰의 기본 "띠리리링" 소리가 납니다. (에러 방지)
                    safeAlarm.soundName = nil
                    
                    do {
                        // 2. 수정된(안전한) 알람 객체로 등록 시도
                        try await AlarmKitManager.shared.scheduleAlarm(from: safeAlarm)
                        print("✅ 시스템 알람 등록 성공")
                    } catch {
                        print("❌ 시스템 알람 등록 실패: \(error)")
                        
                        // 3. 실패 시 롤백 (리스트에서 제거)
                        // 0.5초 딜레이를 줘서 UI가 꼬이는 것을 방지합니다.
//                        try? await AsyncTask.sleep(nanoseconds: 500_000_000)
//                        
//                        if let index = self.alarms.firstIndex(where: { $0.id == newAlarm.id }) {
//                            withAnimation {
////                                self.alarms.remove(at: index)
//                            }
//                            print("↩️ 등록 실패로 롤백됨")
//                        }
                    }
                }
    }
    
    // MARK: - Helper
    private func syncAlarmKit(alarms: [Alarm]) async {}
}
