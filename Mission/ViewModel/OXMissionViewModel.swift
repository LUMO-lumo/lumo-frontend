//
//  OXMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class OXMissionViewModel: BaseMissionViewModel {
    
    // MARK: - UI Properties
    @Published var questionText: String = "로딩 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false     // 정답 이미지 표시용
    
    // MARK: - Mock Mode (테스트용 설정)
    private let isMockMode: Bool = true
    private let mockQuestion = "바나나는 사실 베리류(Berry)에 속한다?"
    private let mockAnswer = "O" // 정답 설정
    
    // MARK: - Initialization
    override init(alarmId: Int = 1) {
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func startOXMission() {
        // [Mock]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real]
        AsyncTask {
            do {
                self.isLoading = true
                
                // Base의 startMission 호출
                if let result = try await super.startMission() {
                    self.contentId = result.contentId
                    self.questionText = result.question
                    print("🌐 [SERVER] 문제 로드 성공: \(result.question)")
                } else {
                    self.errorMessage = "문제를 불러오지 못했습니다."
                }
                
                self.isLoading = false
            } catch {
                self.isLoading = false
                print("❌ [SERVER] 문제 로드 실패: \(error)")
                self.errorMessage = "네트워크 연결을 확인해주세요."
            }
        }
    }
    
    // MARK: - 2. 제출 (버튼 클릭 시)
    func submitAnswer(_ answer: String) {
        // [Mock]
        if isMockMode {
            checkMockAnswer(userAnswer: answer)
            return
        }
        
        // [Real]
        guard let contentId = contentId else {
            print("❌ contentId 없음")
            return
        }
        
        attemptCount += 1
        
        let request = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: answer,
            attemptCount: attemptCount
        )
        
        AsyncTask {
            do {
                self.isLoading = true
                
                // 서버에 정답 확인 요청
                let isSuccess = try await super.submitMission(request: request)
                
                self.isLoading = false
                self.handleSubmissionResult(isCorrect: isSuccess)
                
            } catch {
                self.isLoading = false
                print("❌ 제출 중 에러 발생: \(error)")
                self.errorMessage = "전송 실패. 다시 시도해주세요."
            }
        }
    }
    
    // MARK: - Helper (결과 처리 공통 로직)
    private func handleSubmissionResult(isCorrect: Bool) {

        self.isCorrect = isCorrect
        self.showFeedback = true
        if isCorrect {
            // ✅ 정답일 때 로직 추가됨
            self.feedbackMessage = "정답이에요!"
            
            // 1.5초 뒤에 완료 처리 -> 뷰가 닫힘
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.isMissionCompleted = true
            }} else {
            self.feedbackMessage = "틀렸어요!"
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.showFeedback = false
                self.userAnswer = ""
            }
        }
    }
    
    // MARK: - Mock Helpers
    private func setupMockData() {
        self.isLoading = true
        AsyncTask {
            try? await AsyncTask.sleep(nanoseconds: 500_000_000) // 로딩 흉내
            self.questionText = mockQuestion
            self.isLoading = false
            print("💻 [LOCAL] 테스트 문제 로드 완료")
        }
    }
    
    private func checkMockAnswer(userAnswer: String) {
        AsyncTask {
            // 통신 흉내
            try? await AsyncTask.sleep(nanoseconds: 300_000_000)
            
            let isCorrect = (userAnswer == mockAnswer)
            self.handleSubmissionResult(isCorrect: isCorrect)
        }
    }
}
