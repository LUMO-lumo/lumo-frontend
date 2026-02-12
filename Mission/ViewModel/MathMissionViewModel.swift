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
        
        // [Real] - 부모 메서드 호출 (재사용)
        AsyncTask {
            do {
                // "부모님(super), 미션 시작 요청해주세요. 결과는 배열([MissionStartResult])로 주세요."
                let result: [MissionStartResult] = try await super.startMission()
                
                if let firstProblem = result.first {
                    self.contentId = firstProblem.contentId
                    self.questionText = firstProblem.question
                    print("✅ 문제 로드 완료: \(firstProblem.question)")
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
                // "부모님(super), 제출해주세요. 결과는 MissionSubmitResult로 주세요."
                let result: MissionSubmitResult = try await super.submitMission(request: body)
                
                self.handleSubmissionResult(
                    isCorrect: result.isCorrect,
                    isCompleted: result.isCompleted
                )
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - Helper (UI Logic)
    private func handleSubmissionResult(isCorrect: Bool, isCompleted: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        
        if isCorrect {
            self.feedbackMessage = "정답이에요!"
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                // 부모 메서드 호출
                await super.dismissAlarm()
            }
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
        self.handleSubmissionResult(isCorrect: isCorrect, isCompleted: true)
    }
}
