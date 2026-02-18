//
//  MathMissionViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/12/26.
//

import Foundation
import Combine
import Moya

// 로컬 테스트용 문제 모델
struct LocalMathProblem {
    let question: String
    let answer: String
}

@MainActor
class MathMissionViewModel: BaseMissionViewModel {
    
    // MARK: - Configuration
    // ⭐️ 이 값을 false로 바꾸면 즉시 API 모드로 작동합니다.
    private let isMockMode: Bool = false
    
    // MARK: - UI Properties
    @Published var questionText: String = "문제를 불러오는 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    
    // Math 전용 프로퍼티
    let alarmLabel: String
    
    // 로컬 정답 확인용
    private var localCorrectAnswer: String = ""
    
    // MARK: - 🚨 Local Mock Data Pool (요청하신 데이터)
    private let problemPool: [LocalMathProblem] = [
        LocalMathProblem(question: "127 + 358 = ?", answer: "485"),
        LocalMathProblem(question: "234 - 87 = ?", answer: "147"),
        LocalMathProblem(question: "23 × 15 = ?", answer: "345"),
        LocalMathProblem(question: "144 ÷ 12 = ?", answer: "12"),
        LocalMathProblem(question: "89 + 76 - 34 = ?", answer: "131"),
        LocalMathProblem(question: "256 + 189 = ?", answer: "445"),
        LocalMathProblem(question: "512 - 237 = ?", answer: "275"),
        LocalMathProblem(question: "18 × 24 = ?", answer: "432"),
        LocalMathProblem(question: "225 ÷ 15 = ?", answer: "15"),
        LocalMathProblem(question: "156 + 89 - 67 = ?", answer: "178")
    ]
    
    // MARK: - Initialization
    init(alarmId: Int, alarmLabel: String) {
        self.alarmLabel = alarmLabel
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작
    func startMathMission() {
        // [Mock Mode]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
        isLoading = true
        AsyncTask {
            do {
                            // ✅ [핵심 수정] 결과를 배열([MissionContentDTO])로 캐스팅합니다.
                            // BaseViewModel이나 Service에서 이미 리턴 타입을 [MissionContentDTO]로 수정했다고 가정합니다.
                            if let results = try await super.startMission() as? [MissionContentDTO] {
                                
                                // ✅ 배열에서 첫 번째 문제를 가져옵니다.
                                if let firstProblem = results.first {
                                    self.contentId = firstProblem.contentId
                                    self.questionText = firstProblem.question ?? "문제 내용 없음"
                                    print("✅ [API] 문제 로드 완료: \(self.questionText)")
                                } else {
                                    self.errorMessage = "도착한 문제가 없습니다."
                                    self.questionText = "문제 오류"
                                }
                                
                            } else {
                                // 캐스팅 실패 시 (여전히 객체로 오거나 타입이 안 맞을 때)
                                self.errorMessage = "데이터 형식이 올바르지 않습니다."
                            }
            } catch {
                self.handleError(error)
            }
            self.isLoading = false
        }
    }
    
    // MARK: - 2. 답안 제출
    func submitAnswer() {
        guard !userAnswer.isEmpty else { return }
        
        // [Mock Mode]
        if isMockMode {
            checkMockAnswer()
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
        guard let contentId = contentId else { return }
        
        let body = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: userAnswer,
            attemptCount: self.attemptCount + 1
        )
        
        AsyncTask {
            do {
                // BaseMissionViewModel의 submitMission 호출 (성공 시 내부에서 dismissAlarm 수행)
                let isSuccess = try await super.submitMission(request: body)
                self.handleSubmissionResult(isCorrect: isSuccess)
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - Helper (UI Logic)
    private func handleSubmissionResult(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        
        if isCorrect {
            self.feedbackMessage = "정답이에요!"
            print("🎉 정답입니다!")
            
            // API 모드일 때는 BaseViewModel이 dismissAlarm을 이미 호출했을 것임.
            // Mock 모드일 때는 여기서 수동으로 완료 처리.
            if isMockMode {
                AsyncTask {
                    try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                    self.isMissionCompleted = true
                }
            } else {
                // API 모드에서도 사용자가 정답 피드백을 볼 시간을 줌 (Base가 isMissionCompleted를 true로 만들기 전이라고 가정하거나, UI 흐름에 따라 조정)
                 // 보통 BaseViewModel에서 dismissAlarm 성공 후 isMissionCompleted = true로 설정하므로
                 // 여기서는 별도 처리가 필요 없거나, 애니메이션을 위한 딜레이만 줄 수 있습니다.
            }
            
        } else {
            self.feedbackMessage = "틀렸어요!"
            // 1.5초 후 피드백 숨기고 입력창 초기화
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.showFeedback = false
                self.userAnswer = ""
            }
        }
    }
    
    // 에러 처리
    private func handleError(_ error: Error) {
            // 1. UI용 기본 메시지 설정
            if let missionError = error as? MissionError {
                switch missionError {
                case .serverError(let message):
                    self.errorMessage = message
                default:
                    self.errorMessage = "미션 진행 중 오류가 발생했습니다."
                }
            } else {
                self.errorMessage = "알 수 없는 오류가 발생했습니다."
            }
            
            // 2. 디버깅용 상세 로그 (MoyaError 캐스팅)
            print("\n❌ Error 발생: \(error)")
            
            // 일반 Error는 response 속성이 없으므로 MoyaError로 캐스팅해야 함
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                print("🔢 상태 코드: \(response.statusCode)")
                
                // 📦 [숨겨진 112 bytes 확인하는 코드]
                if let errorBody = String(data: response.data, encoding: .utf8) {
                    print("\n📦 [서버 에러 메시지 디코딩]:")
                    print("👉 \(errorBody)")
                }
            } else {
                print("🌍 네트워크 오류이거나 응답이 없습니다.")
            }
        }
    
    // MARK: - Mock Helpers (Local Logic)
    private func setupMockData() {
        self.isLoading = true
        AsyncTask {
            // 실제 로딩 느낌을 위한 약간의 딜레이
            try? await AsyncTask.sleep(nanoseconds: 500_000_000)
            
            if let randomProblem = self.problemPool.randomElement() {
                self.contentId = 999 // 가상의 ID
                self.questionText = randomProblem.question
                self.localCorrectAnswer = randomProblem.answer
                print("🧪 [Mock] 문제 로드: \(randomProblem.question) / 답: \(randomProblem.answer)")
            }
            
            self.isLoading = false
        }
    }
    
    private func checkMockAnswer() {
        let cleanAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = (cleanAnswer == localCorrectAnswer)
        
        handleSubmissionResult(isCorrect: isCorrect)
    }
}
