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
    var selectedLevel: String = UserDefaults.standard.string(forKey: "MISSION_DIFFICULTY") ?? "MEDIUM"
    
    // UserDefaults 초기화 (앱 켤 때 저장된 값 불러오기)
    // 관례상 변수명은 소문자로 시작 (SmartBriefingEnabled -> smartBriefingEnabled)
    var smartBriefingEnabled: Bool = UserDefaults.standard.bool(forKey: "isSmartBriefing")
    
    // 로그인 체크 (수정됨)
    private var isLoggedIn: Bool {
        // loadSession이 throws를 하므로 try?를 사용하여 에러 발생 시 nil로 처리
        return (try? KeychainManager.standard.loadSession(for: "userSession")) != nil
    }
    
    // MARK: - 1. 스마트 브리핑(또는 미션 난이도 활성화) 토글
    // 함수 이름과 내부 로직 변수명이 약간 매칭되지 않으나, 기존 로직을 유지하며 수정했습니다.
    func updateMissionDifficulty(isEnabled: Bool) {
        // Optimistic UI: 서버 응답 기다리지 않고 즉시 UI/로컬 반영
        self.smartBriefingEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isSmartBriefing")
        print("💾 로컬 설정 저장 완료: \(isEnabled)")
        
        // 로그인 상태라면 서버 동기화 진행
        if isLoggedIn {
            print("📡 서버 동기화 시작...")
            requestServerUpdate(isEnabled: isEnabled)
        } else {
            print("ℹ️ 비로그인 상태: 로컬 설정만 변경됨")
        }
    }
    
    // MARK: - 2. 미션 난이도 변경 (String)
    func updateMissionLevel(level: String) {
        // 1️⃣ [변경 전] 현재 설정값을 임시 저장 (실패 시 롤백용 혹은 로그용)
        let oldLevel = self.selectedLevel
        
        print("⏳ 난이도 변경 요청 중... (\(oldLevel) ➡️ \(level))")
        
        // Optimistic UI 적용 (먼저 UI를 바꿈)
        self.selectedLevel = level
        
        // ✅ [추가] 변경된 난이도를 로컬에 영구 저장 (AlarmDTO에서 갖다 쓰기 위함)
        UserDefaults.standard.set(level, forKey: "MISSION_DIFFICULTY")
        print("💾 로컬 난이도 저장 완료: \(level)")
        
        provider.request(.updateMissionLevel(level: level)) { [weak self] result in
            switch result {
            case .success(let response):
                // 2️⃣ [성공]
                print("✅ 미션 난이도 변경 완료!")
                print("   ㄴ 변경 내역: \(oldLevel) 👉 \(level)")
                print("   ㄴ 응답 상태: \(response.statusCode)")
                
            case .failure(let error):
                // 3️⃣ [실패] UI 롤백
                print("❌ 난이도 변경 실패 (기존 \(oldLevel)로 복구)")
                self?.selectedLevel = oldLevel
                
                // ★ 서버 에러 메시지 확인
                if let response = error.response {
                    print("🔢 상태 코드: \(response.statusCode)")
                    if let message = String(data: response.data, encoding: .utf8) {
                        print("📝 서버 메시지: \(message)")
                    }
                } else {
                    print("🌍 네트워크 연결 문제 (서버 응답 없음)")
                }
                
                // 에러 타입 로그
                print("⚡️ 에러 상세: \(error.localizedDescription)")
                print("====================================================\n")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func requestServerUpdate(isEnabled: Bool) {
        provider.request(.smartVoice(smartvoice: isEnabled)) { result in
            switch result {
            case .success(let response):
                print("✅ 설정 서버 동기화 성공: \(response.statusCode)")
                
            case .failure(let error):
                print("\n================ [❌ 설정 동기화 실패] ================")
                
                if let response = error.response {
                    print("🔢 상태 코드: \(response.statusCode)")
                    if let errorBody = String(data: response.data, encoding: .utf8) {
                        print("📄 서버 에러 메시지: \(errorBody)")
                    }
                } else {
                    print("🌍 네트워크 연결 문제 (서버 응답 없음)")
                }
                print("========================================================\n")
            }
        }
    }
}
