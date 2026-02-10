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
    var SmartBriefingEnabled: Bool = false // UI 반영용

    func updateSmartBriefing(isEnabled: Bool) {
        provider.request(.smartVoice(smartvoice: isEnabled)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.SmartBriefingEnabled = isEnabled
                print("스마트 브리핑 설정 완료: \(response.statusCode)")
                if let jsonString = String(data: response.data, encoding: .utf8) {
                    print("서버 메시지: \(jsonString)")
                }
            case .failure(let error):
                print("설정 변경 실패: \(error.localizedDescription)")
                if let errorResponse = error.response,
                                   let jsonString = String(data: errorResponse.data, encoding: .utf8) {
                                    print("에러 상세 내용: \(jsonString)")
                                }
            }
        }
    }
}
