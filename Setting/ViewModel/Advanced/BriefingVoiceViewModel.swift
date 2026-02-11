//
//  BriefingVoiceViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/5/26.
//

import Foundation
import Moya
import AlarmKit

@Observable
class BriefingVoiceViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    var selectedVoice: String = "WOMAN" // UI 반영용

    func updateVoice(voice: String) {
        provider.request(.updateVoice(voice: voice)) { [weak self] result in
            switch result {
            case .success:
                self?.selectedVoice = voice
                print("브리핑 목소리 설정 변경 완료")
            case .failure(let error):
                print("설정 변경 실패: \(error.localizedDescription)")
            }
        }
    }
}
