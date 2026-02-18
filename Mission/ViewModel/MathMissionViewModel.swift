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
            self.isLoading = true
            
            do {
                print("🚀 [SERVER] 수학 미션 시작 요청...")
                print("현재 요청 중인 Alarm ID: \(self.alarmId)")
                if let results = try await super.startMission() {
                    
                    if let firstProblem = results.first {
                        // 1. [성공] 서버 데이터 적용
                        self.contentId = firstProblem.contentId
                        self.questionText = firstProblem.question ?? "문제 내용 없음"
                        
                        print("🌐 [SERVER] 문제 로드 성공: \(self.questionText)")
                    } else {
                        // 배열은 왔는데 비어있음
                        throw MissionError.serverError(message: "문제 데이터 없음")
                    }
                    
                } else {
                    // 캐스팅 실패 (데이터 형식이 안 맞음)
                    throw MissionError.serverError(message: "데이터 형식이 올바르지 않습니다.")
                }
                
            } catch {
                // 2. [실패] 서버 에러 발생 시 로컬 모드로 전환 (Graceful Degradation)
                print("❌ [SERVER] 문제 로드 실패: \(error)")
                print("⚠️ 서버 연결 실패로 인해 '로컬(Mock) 모드'로 전환합니다.")
                
                // 3. 디버깅용: 서버 에러 메시지 확인 (MoyaError인 경우)
                if let moyaError = error as? MoyaError, let response = moyaError.response {
                    let errorBody = String(data: response.data, encoding: .utf8) ?? "데이터 없음"
                    print("🔍 [DEBUG] 서버 에러 메시지: \(errorBody)")
                }
                
                // 🚨 비상 착륙: 로컬 데이터 세팅
                self.setupMockData()
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
            AsyncTask {
                        try? await AsyncTask.sleep(nanoseconds: 1_500_000_000) // 1.5초 딜레이 (피드백 감상 시간)
                        
                        // UI 업데이트는 메인 스레드에서
                        await MainActor.run {
                            print("🏁 [ViewModel] 정답 확인! 미션 완료 처리합니다.")
                            self.isMissionCompleted = true
                        }
                    }
                    
                } else {
                    // ❌ 오답일 때
                    self.feedbackMessage = "틀렸어요!"
                    AsyncTask {
                        try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                        
                        await MainActor.run {
                            self.showFeedback = false
                            self.userAnswer = ""
                        }
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
