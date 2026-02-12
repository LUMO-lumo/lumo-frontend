//
//  MathMissionViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/12/26.
//

import Foundation
import Combine

@MainActor
class MathMissionViewModel: BaseMissionViewModel {
    
    // MARK: - UI Properties
    @Published var questionText: String = "문제를 불러오는 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    
    // BaseViewModel에 없는 Math 전용 프로퍼티
    let alarmLabel: String
    
    // Mock Mode
    private let isMockMode: Bool = true
    private var mockAnswer: String = "35"
    
    // MARK: - Initialization
    init(alarmId: Int, alarmLabel: String) {
        self.alarmLabel = alarmLabel
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func startMathMission() {
        // [Mock]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real]
        AsyncTask {
            do {
                // 🚨 수정 1: Base가 이제 배열([])이 아니라 단일 객체(MissionStartResult?)를 반환합니다.
                if let result = try await super.startMission() {
                    self.contentId = result.contentId
                    self.questionText = result.question
                    print("✅ 문제 로드 완료: \(result.question)")
                } else {
                    self.errorMessage = "문제를 불러오지 못했습니다."
                }
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - 2. 답안 제출 (View에서 호출)
    func submitAnswer() {
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
                // 🚨 수정 2: Base가 이제 객체가 아니라 성공 여부(Bool)만 반환합니다.
                // (Base 내부에서 정답이면 이미 dismissAlarm을 호출함)
                let isSuccess = try await super.submitMission(request: body)
                
                self.handleSubmissionResult(isCorrect: isSuccess)
                
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - Helper (UI Logic)
    // 🚨 수정 3: Base 로직 변경에 따라 isCompleted 파라미터 제거 (성공이면 무조건 완료로 간주)
    private func handleSubmissionResult(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        
        if isCorrect {
            self.feedbackMessage = "정답이에요!"
            
            // Base에서 이미 dismissAlarm()을 호출했으므로,
            // 여기서는 UI 피드백(동그라미 애니메이션 등)을 보여줄 시간만 벌어줍니다.
            // View는 Base의 @Published isMissionCompleted를 보고 화면을 닫습니다.
        } else {
            self.feedbackMessage = "틀렸어요!"
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
            try? await AsyncTask.sleep(nanoseconds: 500_000_000)
            self.contentId = 999
            self.questionText = "15 + 20"
            self.mockAnswer = "35"
            self.isLoading = false
            print("🧪 [Mock] 데이터 로드 완료")
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
