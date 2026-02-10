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
    private let provider = MoyaProvider<SettingTarget>()
    var selectedSeconds: Int = 20 // UI 반영용

    func updateMissionAlarmTime(seconds: Int) {
        provider.request(.updateSeconds(second: seconds)) { [weak self] result in
            switch result {
            case .success:
                self?.selectedSeconds = seconds
                print("미션 제한시간 설정 변경 완료")
            case .failure(let error):
                print("설정 변경 실패: \(error.localizedDescription)")
            }
        }
    }
}

