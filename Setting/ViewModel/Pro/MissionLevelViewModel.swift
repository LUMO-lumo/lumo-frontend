//
//  MissionDifficultyViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/13/26.
//

import Foundation
import Moya
import AlarmKit

@Observable
class MissionLevelViewModel {
    
    private let provider = MoyaProvider<SettingTarget>()
    
    // MARK: - Properties
    var selectedLevel: String = "MEDIUM" // UI 반영용 (기본값)
    
    // UserDefaults 초기화 (앱 켤 때 저장된 값 불러오기)
    var SmartBriefingEnabled: Bool = UserDefaults.standard.bool(forKey: "isSmartBriefing")
    
    // 로그인 체크
    private var isLoggedIn: Bool {
        return KeychainManager.standard.loadSession(for: "userSession") != nil
    }
    
    // MARK: - 1. 스마트 브리핑 토글 (Bool)
    func updateMissionDifficulty(isEnabled: Bool) {
        // Optimistic UI: 서버 응답 기다리지 않고 즉시 UI/로컬 반영
        self.SmartBriefingEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isSmartBriefing")
        print("💾 로컬 설정 저장 완료: \(isEnabled)")
        
        // 로그인 상태라면 서버 동기화 진행
        if isLoggedIn {
            print("📡 서버 동기화 시작...")
            requestServerUpdate(isEnabled: isEnabled)
        } else {
            print("⚠️ 비로그인 상태: 로컬 설정만 변경됨")
        }
    }
    
    // MARK: - 2. 미션 난이도 변경 (String)
    func updateMissionLevel(level: String) {
        // 1️⃣ [변경 전] 현재 설정값을 임시 저장
        let oldLevel = self.selectedLevel
        
        print("⏳ 난이도 변경 요청 중... (\(oldLevel) ➡️ \(level))")

        // ⚠️ SettingTarget에 .updateMissionLevel 케이스가 있어야 합니다!
        provider.request(.updateMissionLevel(level: level)) { [weak self] result in
            switch result {
            case .success(let response):
                // 2️⃣ [변경 후] 성공 시 값 업데이트 및 로그
                self?.selectedLevel = level
                
                print("✅ 미션 난이도 변경 완료!")
                print("   ㄴ 변경 내역: \(oldLevel) 👉 \(level)")
                print("   ㄴ 응답 상태: \(response.statusCode)")
                
            case .failure(let error):
                // 3️⃣ 실패 시 로그
                print("❌ 난이도 변경 실패 (기존 \(oldLevel) 유지)")
                
                // ★ 서버 에러 메시지 확인
                if let response = error.response,
                   let message = String(data: response.data, encoding: .utf8) {
                    print("\n📝 [서버의 불만사항]: \(message)\n")
                }
                
                // 에러 타입 분석
                switch error {
                case .underlying(let nsError as NSError, _):
                    print("⚡️ 시스템/네트워크 에러: \(nsError.localizedDescription)")
                case .statusCode:
                    print("⚡️ 상태 코드 에러")
                default:
                    print("⚡️ 기타 Moya 에러: \(error.localizedDescription)")
                }
                print("====================================================\n")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func requestServerUpdate(isEnabled: Bool) {
        provider.request(.smartVoice(smartvoice: isEnabled)) { result in
            switch result {
            case .success(let response):
                print("✅ 스마트 브리핑 동기화 성공: \(response.statusCode)")
                
            case .failure(let error):
                print("\n================ [❌ 스마트 브리핑 동기화 실패] ================")
                
                if let response = error.response {
                    print("🔢 상태 코드: \(response.statusCode)")
                    if let errorBody = String(data: response.data, encoding: .utf8) {
                        print("📄 서버 에러 메시지: \(errorBody)")
                    }
                } else {
                    print("🌍 네트워크 연결 문제 (서버 응답 없음)")
                }
                print("==============================================================\n")
            }
        }
    }
}
