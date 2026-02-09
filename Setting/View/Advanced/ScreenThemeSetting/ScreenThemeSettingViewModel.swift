//
//  ScreenThemeSettingViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import Moya
import AlarmKit

@Observable
class ScreenThemeSettingViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    var selectedTheme: String = "Light" // UI 반영용

    func updateTheme(theme: String) {
        provider.request(.updateTheme(theme: theme)) { [weak self] result in
            switch result {
            case .success:
                self?.selectedTheme = theme
                print("화면 테마 설정 변경 완료")
            case .failure(let error):
                print("설정 변경 실패: \(error.localizedDescription)")
            }
        }
    }
}

