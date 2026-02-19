//
//  MissionAlarmSettingViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import AlarmKit
import Foundation
import Moya

@Observable
class MissionAlarmSettingViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    var selectedSeconds: Int = 20 // UI 반영용
    
    func updateMissionAlarmTime(seconds: Int) {
        // 현재 설정된 시간을 임시 변수에 저장 (로그용)
        let oldSeconds = self.selectedSeconds
        
        print("⏳ 미션 제한시간 변경 요청 중... (\(oldSeconds)초 ➡️ \(seconds)초)")
        
        provider.request(.updateSeconds(second: seconds)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // 성공 시 값 업데이트 및 로그 출력
                self.selectedSeconds = seconds
                
                print("✅ 미션 제한시간 설정 변경 완료!")
                print("   ㄴ 변경 내역: \(oldSeconds)초 👉 \(seconds)초")
                print("   ㄴ 응답 상태: \(response.statusCode)")
                
            case .failure(let error):
                // 실패 시 상세 로그 출력
                print("❌ 설정 변경 실패 (기존 \(oldSeconds)초 유지)")
                
                // 서버가 보낸 에러 메시지 확인
                if let response = error.response,
                   let message = String(data: response.data, encoding: .utf8) {
                    print("\n📝 [서버 응답 메시지]: \(message)\n")
                }
                
                // 에러 타입별 상세 분류
                self.logNetworkError(error)
                print("====================================================\n")
            }
        }
    }
    
    // MARK: - Logging Helper
    
    private func logNetworkError(_ error: MoyaError) {
        switch error {
        case .underlying(let nsError as NSError, _):
            print("⚡️ 시스템/네트워크 에러: \(nsError.localizedDescription)")
        case .statusCode:
            print("⚡️ 상태 코드 에러 (200~299 범위 벗어남)")
        case .jsonMapping:
            print("⚡️ JSON 파싱 실패 (서버 응답 형식이 다름)")
        default:
            print("⚡️ 기타 Moya 에러: \(error.localizedDescription)")
        }
    }
}
