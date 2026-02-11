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
                // 성공 시 UI는 이미 바뀌어 있으므로 로그만 출력
                print("스마트 브리핑 동기화 완료: \(response.statusCode)")
                
                // (디버깅용) 서버 메시지 확인
                if let jsonString = String(data: response.data, encoding: .utf8) {
                    print("서버 메시지: \(jsonString)")
                }
                
            case .failure(let error):
                print("설정 동기화 실패: \(error.localizedDescription)")
                
                // [선택 사항]
                // 서버 저장이 매우 중요한 경우, 여기서 실패 시 UI를 다시 되돌릴 수도 있습니다.
                // self?.SmartBriefingEnabled = !isEnabled
                // UserDefaults.standard.set(!isEnabled, forKey: "isSmartBriefing")
            }
        }
    }
}
