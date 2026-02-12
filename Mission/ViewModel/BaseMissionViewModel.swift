//
//  BaseMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Combine
import Moya
import _Concurrency

// Moya Task 충돌 방지
typealias AsyncTask = _Concurrency.Task

@MainActor
class BaseMissionViewModel: NSObject, ObservableObject {
    
    // MARK: - 공통 프로퍼티
    // 자식 클래스에서 사용할 Provider (Base에서 관리)
    let provider = MoyaProvider<MissionTarget>()
    
    var alarmId: Int
    var contentId: Int?
    var attemptCount: Int = 0
    
    // UI 상태 (공통)
    @Published var isMissionCompleted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init(alarmId: Int) {
        self.alarmId = alarmId
    }
    
    // MARK: - 공통 API 1: 미션 시작
    // T: 서버에서 받아올 데이터 타입 (예: [MissionStartResult])
    // 함수명 startMission 유지, 비동기 반환으로 변경
    func startMission<T: Codable>() async throws -> T {
        isLoading = true
        defer { isLoading = false } // 함수 종료 시 로딩 끄기
        
        let result = await provider.request(.startMission(alarmId: alarmId))
        return try handleResponse(result)
    }
    
    // MARK: - 공통 API 2: 답안 제출
    // Body: 보낼 데이터 타입, R: 받을 데이터 타입
    // 함수명 submitMission 유지
    func submitMission<Body: Encodable, R: Codable>(request: Body) async throws -> R {
        attemptCount += 1
        isLoading = true
        defer { isLoading = false }
        
        let result = await provider.request(.submitMission(alarmId: alarmId, request: request))
        return try handleResponse(result)
    }
    
    // MARK: - 공통 API 3: 알람 해제
    // 함수명 dismissAlarm 유지
    func dismissAlarm() async {
        let requestBody = DismissAlarmRequest(
            alarmId: alarmId,
            dismissType: "MISSION",
            snoozeCount: 0
        )
        
        let result = await provider.request(.dismissAlarm(alarmId: alarmId, request: requestBody))
        
        switch result {
        case .success(let response):
            // 성공 여부만 확인하면 되므로 간단하게 처리
            if let decoded = try? response.map(BaseResponse<DismissAlarmResult>.self), decoded.success {
                print("✅ [Base] 알람 해제 성공")
                self.isMissionCompleted = true
            } else {
                self.errorMessage = "알람 해제 실패"
            }
        case .failure(let error):
            print("❌ [Base] 해제 실패: \(error)")
            self.errorMessage = "네트워크 오류가 발생했습니다."
        }
    }
    
    // MARK: - 내부 헬퍼: 응답 처리
    private func handleResponse<T: Codable>(_ result: Result<Response, MoyaError>) throws -> T {
        switch result {
        case .success(let response):
            _ = try response.filterSuccessfulStatusCodes()
            let decoded = try response.map(BaseResponse<T>.self)
            
            if decoded.success, let data = decoded.result {
                return data
            } else {
                throw MissionError.serverError(message: decoded.message)
            }
            
        case .failure(let error):
            throw error
        }
    }
}

// 에러 타입 정의
enum MissionError: Error {
    case serverError(message: String)
}
