//
//  SmartBriefingViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/10/26.
//

import Foundation
import Moya
import AlarmKit

@Observable
class SmartBriefingViewModel {
    
    private let provider = MoyaProvider<SettingTarget>()
    // 앱을 켤 때 UserDefaults에 저장된 값을 가져와서 초기화합니다. (기본값 false)
    var SmartBriefingEnabled: Bool = UserDefaults.standard.bool(forKey: "isSmartBriefing")
    // 키체인에 저장된 세션(토큰)이 있는지 확인하는 연산 프로퍼티
    private var isLoggedIn: Bool {
        return KeychainManager.standard.loadSession(for: "userSession") != nil
    }
    func updateSmartBriefing(isEnabled: Bool) {
        // 서버 응답과 상관없이 UI를 즉시 업데이트하고(Optimistic UI), 로컬에 저장합니다.
        self.SmartBriefingEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isSmartBriefing")
        print("로컬 설정 저장 완료: \(isEnabled)")
        // 토큰이 있을 때만(로그인 상태) 서버에 요청을 보냅니다.
        if isLoggedIn {
            print("서버 동기화 시작")
            requestServerUpdate(isEnabled: isEnabled)
        } else {
            print("로컬 설정만 변경")
        }
    }

    private func requestServerUpdate(isEnabled: Bool) {
        provider.request(.smartVoice(smartvoice: isEnabled)) { [weak self] result in
            switch result {
            case .success(let response):
                // 200~299 사이 성공 범위
                print("✅ 스마트 브리핑 동기화 성공: \(response.statusCode)")
                
                // (필요 시) 성공 응답 확인
                // if let jsonString = String(data: response.data, encoding: .utf8) {
                //    print("서버 응답: \(jsonString)")
                // }
                
            case .failure(let error):
                print("\n================ [❌ 동기화 실패 로그] ================")
                
                // 1. HTTP 상태 코드 확인 (예: 400, 401, 500)
                if let response = error.response {
                    print("🔢 상태 코드: \(response.statusCode)")
                    
                    // 2. ★ 핵심: 서버가 보낸 에러 메시지 본문(Body) 확인
                    // 보통 여기에 "잘못된 파라미터입니다" 같은 진짜 이유가 들어있습니다.
                    if let errorBody = String(data: response.data, encoding: .utf8) {
                        print("📄 서버 에러 메시지: \(errorBody)")
                    }
                } else {
                    print("🌍 네트워크 연결 문제 혹은 타임아웃 (서버 응답 없음)")
                }
                
                // 3. 에러의 구체적인 타입 확인 (MoyaError)
                switch error {
                case .underlying(let nsError as NSError, _):
                    print("⚡️ 시스템/네트워크 에러: \(nsError.localizedDescription)")
                    print("   (Code: \(nsError.code), Domain: \(nsError.domain))")
                case .statusCode:
                    print("⚡️ 상태 코드 에러 (200~299 범위 벗어남)")
                case .jsonMapping:
                    print("⚡️ 응답 데이터 JSON 파싱(디코딩) 실패")
                case .stringMapping:
                    print("⚡️ 문자열 변환 실패")
                default:
                    print("⚡️ 기타 Moya 에러: \(error.localizedDescription)")
                }
                
                print("====================================================\n")
                
                // [선택 사항] UI 롤백 로직
                // self?.SmartBriefingEnabled = !isEnabled
            }
        }
    }
}
