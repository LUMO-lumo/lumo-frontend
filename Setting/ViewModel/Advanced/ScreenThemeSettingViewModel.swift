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
    var selectedTheme: String = "LIGHT" // UI 반영용

    func updateTheme(theme: String) {
            // 1. 요청 보내기 직전, 현재 설정된 테마를 'oldTheme'에 저장해둡니다.
            let oldTheme = self.selectedTheme
            
            print("⏳ 테마 변경 요청 중... (\(oldTheme) ➡️ \(theme))")

            provider.request(.updateTheme(theme: theme)) { [weak self] result in
                switch result {
                case .success:
                    // 2. 서버 통신 성공 시
                    self?.selectedTheme = theme
                    
                    print("✅ 화면 테마 설정 변경 완료!")
                    print("   ㄴ 변경 내역: \(oldTheme) 👉 \(theme)") // 여기서 확인 가능!
                    
                case .failure(let error):
                    // 3. 실패 시 로그 (기존 코드 유지)
                    print("❌ 요청 실패: 400 Bad Request (테마 변경 실패)")
                    print("   ㄴ 유지된 테마: \(oldTheme)") // 실패했으니 원래 값 유지됨을 확인
                    
                    // (아래는 기존 에러 디버깅 코드)
                    if let response = error.response,
                       let message = String(data: response.data, encoding: .utf8) {
                        print("\n📝 [서버의 불만사항]: \(message)\n")
                    }
                    
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
                }
            }
        }
}

