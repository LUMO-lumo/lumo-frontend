//
//  BaseMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Combine
import Moya

// 1. 공통 기능을 담은 부모 클래스
class BaseMissionViewModel: NSObject, ObservableObject {
    // MARK: - 공통 프로퍼티
    let provider = MoyaProvider<MissionTarget>()
    var alarmId: Int
    var contentId: Int?
    var attemptCount: Int = 0
    
    // UI 상태 (공통)
    @Published var isMissionCompleted: Bool = false
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    
    init(alarmId: Int) {
        self.alarmId = alarmId
    }
    
    // MARK: - 공통 API 1: 미션 시작 (문제 받아오기)
    // 자식 클래스에서 결과 처리를 다르게 할 수 있도록 completion handler 제공
    func startMission(completion: @escaping (MissionStartResult?) -> Void) {
        provider.request(.startMission(alarmId: alarmId)) { result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try response.map(BaseResponse<MissionStartResult>.self)
                    if let data = decoded.result {
                        self.contentId = data.contentId
                        completion(data) // 데이터 처리는 자식에게 위임
                    }
                } catch {
                    print("Decoding Error")
                }
            case .failure(let error):
                
                print("Network Error: \(error)")
                
                // ⭐️ MoyaError에서 response를 꺼내고, 그 안의 data를 읽어야 합니다.
                if let response = error.response {
                    if let str = String(data: response.data, encoding: .utf8) {
                        print("📝 [403 상세 내용]: \(str)")
                    }
                    print("📊 상태 코드: \(response.statusCode)")
                } else {
                    print("❌ 응답 데이터 자체가 없습니다 (네트워크 연결 끊김 등)")
                }
            }
        }
    }
    
    // MARK: - 공통 API 2: 답안 제출 (요청 바디만 다름)
    // T는 Encodable을 따르는 어떤 데이터든 가능 (String, Struct 등)
    func submitMission<T: Encodable>(body: T, completion: @escaping (Bool) -> Void) {
        guard let _ = contentId else { return }
        attemptCount += 1
        
        provider.request(.submitMission(alarmId: alarmId, request: body)) { result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try response.map(BaseResponse<MissionSubmitResult>.self)
                    if let data = decoded.result {
                        completion(data.isCorrect) // 성공 여부만 자식에게 전달
                    }
                } catch {
                    print("Decoding Error")
                }
            case .failure(let error):
                print("Network Error: \(error)")
            }
        }
    }
    
    // MARK: - 공통 API 3: 알람 해제 (완벽히 동일)
    func dismissAlarm() {
        let request = DismissAlarmRequest(alarmId: alarmId, dismissType: "MISSION", snoozeCount: 0)
        
        provider.request(.dismissAlarm(alarmId: alarmId, request: request)) { [weak self] result in
            switch result {
            case .success:
                print("알람 해제 성공")
                self?.isMissionCompleted = true
            case .failure(let error):
                print("해제 실패: \(error)")
            }
        }
    }
}
