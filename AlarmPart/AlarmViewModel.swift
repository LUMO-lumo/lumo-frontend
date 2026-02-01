import SwiftUI
import Combine
import Foundation
import Moya


//알람 내용물을 가져오는 내용의 코드로 작성 예정***********


class AlarmViewModel: ObservableObject {
    
    // UI에서 관찰하는 알람 데이터 리스트(일단 더미 데이터 사용)
    @Published var alarms: [Alarm] = []
    
    // [Server] 나중에 실제 서버 통신을 할 때 사용할 Provider 객체
    // private let provider = MoyaProvider<AlarmAPI>()
    
    init() {
        // ViewModel이 생성될 때 초기 더미 데이터를 불러옵니다.
        fetchAlarms()
    }
    
    // MARK: - READ (알람 목록 불러오기)
    func fetchAlarms() {
        print(" 서버에서 알람 목록을 불러오는 중...")
        
        // [Server Code Placeholder]
        // provider.request(.getAlarms) { result in
        //     switch result {
        //     case .success(let response):
        //         // 성공 시 받은 데이터를 self.alarms에 할당
        //     case .failure(let error):
        //         print("Error: \(error)")
        //     }
        // }
        
        // [Current Dummy Code] 현재는 더미 데이터를 로드합니다.
        self.alarms = Alarm.dummyData
    }
    
    // MARK: - DELETE 알람 삭제(나중에 서버하고 연결)
    func deleteAlarm(id: UUID) {
        print(" 알람 삭제 요청: \(id)")
        
        // 1. UI 즉시 반영 (낙관적 업데이트: 서버 응답 기다리지 않고 먼저 삭제)
        if let index = alarms.firstIndex(where: { $0.id == id }) {
            alarms.remove(at: index)
        }
        
        // [Server Code Placeholder]
        // provider.request(.deleteAlarm(id: id)) { result in
        //     // 실패 시 다시 롤백하거나 에러 메시지 표시
        // }
    }
    
    // MARK: - UPDATE 알람 수정(서버하고 연결)
    func updateAlarm(_ updatedAlarm: Alarm) {
        print(" 알람 수정 요청: \(updatedAlarm.id)")
        
        // 1. UI 즉시 반영
        if let index = alarms.firstIndex(where: { $0.id == updatedAlarm.id }) {
            alarms[index] = updatedAlarm
        }
        
        // [Server Code Placeholder]
        // provider.request(.updateAlarm(data: updatedAlarm)) { result in
        //     // 서버 업데이트 로직
        // }
    }
    
    // MARK: - CREATE (새 알람 추가)
    func addAlarm(_ newAlarm: Alarm) {
        print(" 새 알람 추가 요청")
        
        // 1. UI 즉시 반영
        alarms.append(newAlarm)
        
        // [Server Code Placeholder]
        // provider.request(.createAlarm(data: newAlarm)) { result in
        //     // 서버 저장 후 ID 등을 받아와서 갱신할 수도 있음
        // }
    }
}
