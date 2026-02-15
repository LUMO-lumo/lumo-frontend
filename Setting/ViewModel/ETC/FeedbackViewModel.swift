//
//  FeedbackViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/15/26.
//

import Foundation
import Moya
import SwiftUI

struct CommonResponse: Decodable {
    let success: Bool
    let message: String?
}

@Observable
class FeedbackViewModel {
    // MARK: - Input Properties (View와 바인딩)
    var title: String = ""
    var content: String = ""
    var email: String = ""
    
    // MARK: - State Properties
    var isLoading: Bool = false
    var isSuccess: Bool = false     // 전송 성공 시 화면 닫기용
    var errorMessage: String? = nil // 에러 메시지
    
    private let provider = MoyaProvider<FeedbackTarget>()
    
    // 유효성 검사 (입력값이 비어있는지 확인)
    var isValid: Bool {
        return !title.isEmpty && !content.isEmpty && !email.isEmpty
    }
    
    // MARK: - Methods
    func sendFeedback() {
        guard isValid else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // 요청 모델 생성
        let request = FeedbackRequest(title: title, content: content, email: email)
        
        provider.request(.sendFeedback(request: request)) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                do {
                    _ = try response.filterSuccessfulStatusCodes()
                    // 응답이 오면 성공으로 처리 (서버 응답 구조에 따라 수정 가능)
                    self.isSuccess = true
                    print("피드백 전송 성공")
                } catch {
                    print("전송 실패: \(error)")
                    self.errorMessage = "전송에 실패했습니다. 다시 시도해주세요."
                }
                
            case .failure(let error):
                print("네트워크 에러: \(error)")
                self.errorMessage = "서버 연결에 실패했습니다."
            }
        }
    }
}
