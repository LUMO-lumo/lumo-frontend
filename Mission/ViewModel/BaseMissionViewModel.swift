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
    let provider: MoyaProvider<MissionTarget>
    
    var alarmId: Int
    var contentId: Int?
    var attemptCount: Int = 0
    
    // UI 상태
    @Published var isMissionCompleted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init(alarmId: Int) {
        self.alarmId = alarmId
        
        // ⭐️ 토큰 설정 (403 에러 방지)
        let token = UserDefaults.standard.string(forKey: "accessToken") ?? ""
        // 키체인 사용 시: let token = KeychainManager.standard.loadSession(for: "userSession")?.accessToken ?? ""
        
        let authPlugin = AccessTokenPlugin { _ in token }
        self.provider = MoyaProvider<MissionTarget>(plugins: [authPlugin])
    }
    
    // MARK: - 공통 API 1: 미션 시작
    func startMission() async throws -> MissionStartResult? {
        isLoading = true
        defer { isLoading = false }
        
        let result = await provider.asyncRequest(.startMission(alarmId: alarmId))
        
        switch result {
        case .success(let response):
            let decoded = try response.map(BaseResponse<MissionStartResult>.self)
            
            if let data = decoded.result {
                // 🚨 [수정] 모델 정의에 맞춰 'missionContentId' -> 'contentId'로 변경
                self.contentId = data.contentId
                return data
            } else {
                throw MissionError.serverError(message: decoded.message)
            }
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - 공통 API 2: 답안 제출
    // 구체적인 타입(MissionSubmitRequest)을 사용하여 복잡한 제네릭 에러 방지
    func submitMission(request: MissionSubmitRequest) async throws -> Bool {
        attemptCount += 1
        isLoading = true
        defer { isLoading = false }
        
        let result = await provider.asyncRequest(.submitMission(alarmId: alarmId, request: request))
        
        switch result {
        case .success(let response):
            let decoded = try response.map(BaseResponse<MissionSubmitResult>.self, using: JSONDecoder())
            
            if let data = decoded.result {
                if data.isCorrect {
                    // 정답이면 알람 해제 자동 호출
                    print("🎉 [Base] 정답입니다! 알람 해제를 요청합니다.")
                    await dismissAlarm()
                    return true
                } else {
                    return false
                }
            }
            return false
            
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - 공통 API 3: 알람 해제
    func dismissAlarm() async {
        let requestBody = DismissAlarmRequest(
            alarmId: alarmId,
            dismissType: "MISSION",
            snoozeCount: 0
        )
        
        let result = await provider.asyncRequest(.dismissAlarm(alarmId: alarmId, request: requestBody))
        
        if case .success(let response) = result {
            // 성공 여부만 간단히 체크 (200번대 상태코드)
            if response.statusCode >= 200 && response.statusCode < 300 {
                print("✅ [Base] 알람 해제 성공")
                self.isMissionCompleted = true
            } else {
                print("⚠️ [Base] 알람 해제 실패 코드: \(response.statusCode)")
                self.errorMessage = "알람 해제 실패 (상태코드: \(response.statusCode))"
            }
        }
    }
}

extension Moya.Response: @unchecked @retroactive Sendable {}

// MARK: - Moya Async 확장 (필수)
extension MoyaProvider {
    func asyncRequest(_ target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { continuation in
            self.request(target) { result in
                // 이제 Response와 MoyaError가 Sendable이 되었으므로,
                // Result<Response, MoyaError>도 자동으로 Sendable이 됩니다.
                // 따라서 그냥 넘겨도 에러가 나지 않습니다.
                continuation.resume(returning: result)
            }
        }
    }
}

// 에러 타입
enum MissionError: Error {
    case serverError(message: String)
}
