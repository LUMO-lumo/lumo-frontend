//
//  TypingMissionViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/13/26.
//
import Foundation
import Combine
import SwiftUI

@MainActor
class TypingMissionViewModel: BaseMissionViewModel {
    
    // MARK: - UI Properties
    @Published var questionText: String = "문제를 불러오는 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    
    // BaseViewModel에 없는 Math 전용 프로퍼티
    let alarmLabel: String
    
    // MARK: - Mock Mode (테스트용 설정)
    private let isMockMode: Bool = true
    private let mockQuestion = "할 수 있다!"
    private let mockAnswer = "할 수 있다!" // 정답 설정
    
    // MARK: - Initialization
    init(alarmId: Int, alarmLabel: String) {
        self.alarmLabel = alarmLabel
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func startTypingMission() {
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
        guard !userAnswer.isEmpty else { return }
        
        // [Mock]
        if isMockMode {
            checkMockAnswer()
            return
        }
        
        // [Real]
        guard let contentId = contentId else { return }
        
        // 보낼 데이터 준비
        let body = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: userAnswer,
            attemptCount: self.attemptCount + 1
        )
        
        AsyncTask {
            do {
                self.isLoading = true
                
                // 서버에 정답 확인 요청
                let isSuccess = try await super.submitMission(request: body)
                
                self.isLoading = false
                self.handleSubmissionResult(isCorrect: isSuccess)
                
            } catch {
                self.isLoading = false
                print("❌ 제출 중 에러 발생: \(error)")
                self.errorMessage = "전송 실패. 다시 시도해주세요."
            }
        }
    }
    
    // MARK: - Helper (UI Logic)
    // 🚨 수정 3: Base 로직 변경에 따라 isCompleted 파라미터 제거 (성공이면 무조건 완료로 간주)
    private func handleSubmissionResult(isCorrect: Bool) {

        self.isCorrect = isCorrect
        self.showFeedback = true
        if isCorrect {
            self.feedbackMessage = "잘했어요!"
            
            // Base에서 이미 dismissAlarm()을 호출했으므로,
            // 여기서는 UI 피드백(동그라미 애니메이션 등)을 보여줄 시간만 벌어줍니다.
            // View는 Base의 @Published isMissionCompleted를 보고 화면을 닫습니다.

        } else {
            self.feedbackMessage = "다시 시도해주세요"
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.showFeedback = false
                self.userAnswer = ""
            }
        }
    }
    
    // 에러 처리
    private func handleError(_ error: Error) {
        if let missionError = error as? MissionError {
            switch missionError {
            case .serverError(let message):
                self.errorMessage = message
            }
        } else {
            self.errorMessage = "오류가 발생했습니다."
        }
        print("❌ Error: \(error)")
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
    
    private func checkMockAnswer() {
        let isCorrect = (userAnswer == mockAnswer)

        // Mock 모드일 때는 수동으로 dismiss 처리 필요
        if isCorrect {
            self.handleSubmissionResult(isCorrect: true)
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.isMissionCompleted = true // Mock 완료 처리
            }
        } else {
            self.handleSubmissionResult(isCorrect: false)
        }
    }
}
