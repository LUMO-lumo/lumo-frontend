//
//  SmartBriefingViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/10/26.
//

import AlarmKit
import Foundation
import Moya

@Observable
class SmartBriefingViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    
    // 앱을 켤 때 UserDefaults에 저장된 값을 가져와서 초기화 (기본값 false)
    var smartBriefingEnabled: Bool = UserDefaults.standard.bool(forKey: "isSmartBriefing")
    
    // 키체인에 저장된 세션(토큰) 유무 확인
    private var isLoggedIn: Bool {
        return (try? KeychainManager.standard.loadSession(for: "userSession")) != nil
    }
    
    func updateSmartBriefing(isEnabled: Bool) {
        // 1. Optimistic UI: UI 즉시 업데이트 및 로컬 저장
        self.smartBriefingEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isSmartBriefing")
        print("💾 로컬 설정 저장 완료: \(isEnabled)")
        
        // 2. 로그인 상태 확인 후 서버 동기화
        if isLoggedIn {
            print("🔄 서버 동기화 시작...")
            requestServerUpdate(isEnabled: isEnabled)
        } else {
            print("ℹ️ 비로그인 상태: 로컬 설정만 변경됨")
        }
    }
    
    private func requestServerUpdate(isEnabled: Bool) {
        provider.request(.smartVoice(smartvoice: isEnabled)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("✅ 스마트 브리핑 서버 동기화 성공 (Code: \(response.statusCode))")
                
            case .failure(let error):
                self.logSyncError(error)
                
                // [선택 사항] 실패 시 UI 롤백 로직 필요 시 주석 해제
                /*
                self.smartBriefingEnabled = !isEnabled
                UserDefaults.standard.set(!isEnabled, forKey: "isSmartBriefing")
                */
            }
        }
    }
    
    // MARK: - Logging Helper
    
    private func logSyncError(_ error: MoyaError) {
        print("\n================ [❌ 동기화 실패 로그] ================")
        
        if let response = error.response {
            print("🔢 상태 코드: \(response.statusCode)")
            if let errorBody = String(data: response.data, encoding: .utf8) {
                print("📄 서버 에러 메시지: \(errorBody)")
            }
        } else {
            print("🌍 네트워크 연결 문제 혹은 타임아웃 (서버 응답 없음)")
        }
        
        switch error {
        case .underlying(let nsError as NSError, _):
            print("⚡️ 시스템/네트워크 에러: \(nsError.localizedDescription)")
        case .statusCode:
            print("⚡️ 상태 코드 에러")
        case .jsonMapping:
            print("⚡️ JSON 파싱 실패")
        default:
            print("⚡️ 기타 Moya 에러: \(error.localizedDescription)")
        }
        print("====================================================\n")
    }
}
