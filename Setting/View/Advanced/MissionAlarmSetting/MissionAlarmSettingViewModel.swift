//
//  MissionAlarmSettingViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import Moya
import AlarmKit

@Observable
class MissionAlarmSettingViewModel {
    private let provider = MoyaProvider<AlarmTarget>()
    var selectedSeconds: Int = 20 // UI 반영용

    func updateGlobalMissionDuration(seconds: Int) {
        provider.request(.updateSetting(duration: seconds)) { [weak self] result in
            switch result {
            case .success:
                self?.selectedSeconds = seconds
                // ⭐️ 성공 시 AlarmKit에 기본 미션 시간 적용
                // AlarmKit.shared.defaultMissionDuration = seconds
                print("서버 설정 변경 및 AlarmKit 동기화 완료")
            case .failure(let error):
                print("설정 변경 실패: \(error.localizedDescription)")
            }
        }
    }
}

