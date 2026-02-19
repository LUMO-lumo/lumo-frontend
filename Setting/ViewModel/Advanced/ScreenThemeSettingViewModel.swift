//
//  ScreenThemeSettingViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import AlarmKit
import Foundation
import Moya

@Observable
class ScreenThemeSettingViewModel {
    private let provider = MoyaProvider<SettingTarget>()
    var selectedTheme: String = "LIGHT" // UI 반영용
    
    func updateTheme(theme: String) {
        // 요청 전 현재 테마 저장 (로그용)
        let oldTheme = self.selectedTheme
        
        print("⏳ 테마 변경 요청 중... (\(oldTheme) ➡️ \(theme))")
        
        provider.request(.updateTheme(theme: theme)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // 서버 통신 성공 시 업데이트
                self.selectedTheme = theme
                
                print("✅ 화면 테마 설정 변경 완료!")
                print("   ㄴ 변경 내역: \(oldTheme) 👉 \(theme)")
                print("   ㄴ 응답 상태: \(response.statusCode)")
                
            case .failure(let error):
                // 실패 시 상세 로그 출력
                print("❌ 요청 실패: 테마 변경에 실패했습니다.")
                print("   ㄴ 유지된 테마: \(oldTheme)")
                
                // 서버 에러 메시지 확인
                if let response = error.response,
                   let message = String(data: response.data, encoding: .utf8) {
                    print("\n📝 [서버 응답 메시지]: \(message)\n")
                }
                
                // 에러 타입별 상세 분류 로깅
                self.logNetworkError(error)
                print("====================================================\n")
            }
        }
    }
    
    // MARK: - Logging Helper
    
    private func logNetworkError(_ error: MoyaError) {
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
    }
}
