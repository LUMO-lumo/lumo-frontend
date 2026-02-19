//
//  MissionDifficultyViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/13/26.
//

import AlarmKit
import Foundation
import Moya

@Observable
class MissionLevelViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    
    // MARK: - Properties
    
    var selectedLevel: String = UserDefaults.standard.string(forKey: "MISSION_DIFFICULTY") ?? "MEDIUM"
    var smartBriefingEnabled: Bool = UserDefaults.standard.bool(forKey: "isSmartBriefing")
    
    private var isLoggedIn: Bool {
        return (try? KeychainManager.standard.loadSession(for: "userSession")) != nil
    }
    
    // MARK: - Public Methods
    
    /// 스마트 브리핑 활성화 여부 업데이트
    func updateMissionDifficulty(isEnabled: Bool) {
        // Optimistic UI: 즉시 반영
        self.smartBriefingEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isSmartBriefing")
        print("💾 로컬 설정 저장 완료: \(isEnabled)")
        
        if isLoggedIn {
            print("📡 서버 동기화 시작...")
            requestServerUpdate(isEnabled: isEnabled)
        } else {
            print("ℹ️ 비로그인 상태: 로컬 설정만 변경됨")
        }
    }
    
    /// 미션 난이도 레벨 업데이트
    func updateMissionLevel(level: String) {
        let oldLevel = self.selectedLevel
        
        print("⏳ 난이도 변경 요청 중... (\(oldLevel) ➡️ \(level))")
        
        // Optimistic UI 및 로컬 저장
        self.selectedLevel = level
        UserDefaults.standard.set(level, forKey: "MISSION_DIFFICULTY")
        print("💾 로컬 난이도 저장 완료: \(level)")
        
        provider.request(.updateMissionLevel(level: level)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("✅ 미션 난이도 변경 완료!")
                print("   ㄴ 변경 내역: \(oldLevel) 👉 \(level)")
                print("   ㄴ 응답 상태: \(response.statusCode)")
                
            case .failure(let error):
                // 실패 시 UI 롤백
                print("❌ 난이도 변경 실패 (기존 \(oldLevel)로 복구)")
                self.selectedLevel = oldLevel
                UserDefaults.standard.set(oldLevel, forKey: "MISSION_DIFFICULTY")
                
                self.logNetworkError(error, title: "난이도 변경 실패")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func requestServerUpdate(isEnabled: Bool) {
        provider.request(.smartVoice(smartvoice: isEnabled)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("✅ 설정 서버 동기화 성공: \(response.statusCode)")
            case .failure(let error):
                self.logNetworkError(error, title: "설정 동기화 실패")
            }
        }
    }
    
    private func logNetworkError(_ error: MoyaError, title: String) {
        print("\n================ [❌ \(title)] ================")
        
        if let response = error.response {
            print("🔢 상태 코드: \(response.statusCode)")
            if let errorBody = String(data: response.data, encoding: .utf8) {
                print("📄 서버 에러 메시지: \(errorBody)")
            }
        } else {
            print("🌍 네트워크 연결 문제 (서버 응답 없음)")
        }
        
        print("⚡️ 에러 상세: \(error.localizedDescription)")
        print("========================================================\n")
    }
}
