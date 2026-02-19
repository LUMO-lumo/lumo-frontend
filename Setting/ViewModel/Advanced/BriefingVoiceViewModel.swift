//
//  BriefingVoiceViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/5/26.
//

import AlarmKit
import Foundation
import Moya

@Observable
class BriefingVoiceViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    var selectedVoice: String = "WOMAN" // UI 반영용
    
    func updateVoice(voice: String) {
        print("🗣 브리핑 목소리 변경 요청 중... (\(selectedVoice) ➡️ \(voice))")
        
        provider.request(.updateVoice(voice: voice)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.selectedVoice = voice
                print("✅ 브리핑 목소리 설정 변경 완료!")
                print("   ㄴ 응답 상태: \(response.statusCode)")
                
            case .failure(let error):
                print("❌ 설정 변경 실패: \(error.localizedDescription)")
                
                // 서버 응답 메시지가 있을 경우 추가 출력
                if let response = error.response,
                   let message = String(data: response.data, encoding: .utf8) {
                    print("   ㄴ 서버 메시지: \(message)")
                }
            }
        }
    }
}
