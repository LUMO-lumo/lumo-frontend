//
//  TypingMissionViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/13/26.
//

import Foundation
import Combine
import SwiftUI
import Moya

// 로컬 테스트용 문제 모델
struct LocalTypingProblem {
    let question: String
    let answer: String
}

@MainActor
class TypingMissionViewModel: BaseMissionViewModel {
    
    // MARK: - Configuration
    // ⭐️ 이 값을 false로 바꾸면 API 모드로 작동합니다.
    private var isMockMode: Bool
    
    // MARK: - UI Properties
    @Published var questionText: String = "문제를 불러오는 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    
    // Typing 전용 프로퍼티
    let alarmLabel: String
    
    // 로컬 정답 확인용
    private var localCorrectAnswer: String = ""
    
    // MARK: - 🚨 Local Mock Data Pool (요청하신 데이터)
    private let problemPool: [LocalTypingProblem] = [
        LocalTypingProblem(question: "일찍 일어나는 새가 벌레를 잡는다", answer: "일찍 일어나는 새가 벌레를 잡는다"),
        LocalTypingProblem(question: "시작이 반이다", answer: "시작이 반이다"),
        LocalTypingProblem(question: "티끌 모아 태산", answer: "티끌 모아 태산"),
        LocalTypingProblem(question: "백문이 불여일견", answer: "백문이 불여일견"),
        LocalTypingProblem(question: "천리길도 한 걸음부터", answer: "천리길도 한 걸음부터"),
        LocalTypingProblem(question: "로마는 하루아침에 이루어지지 않았다", answer: "로마는 하루아침에 이루어지지 않았다"),
        LocalTypingProblem(question: "급할수록 돌아가라", answer: "급할수록 돌아가라"),
        LocalTypingProblem(question: "소 잃고 외양간 고친다", answer: "소 잃고 외양간 고친다"),
        LocalTypingProblem(question: "하늘은 스스로 돕는 자를 돕는다", answer: "하늘은 스스로 돕는 자를 돕는다"),
        LocalTypingProblem(question: "구슬이 서 말이라도 꿰어야 보배", answer: "구슬이 서 말이라도 꿰어야 보배")
    ]
    
    // MARK: - Initialization
    init(alarmId: Int, alarmLabel: String) {
        self.alarmLabel = alarmLabel
        
        // ✅ [핵심] ID가 -1이면 테스트 모드(Mock)로 강제 설정
        self.isMockMode = (alarmId == -1)
        
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func startTypingMission() {
        // [Mock Mode]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
        AsyncTask {
            self.isLoading = true
            
            do {
                print("🚀 [SERVER] 거리 미션 시작 요청...")
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
    
    // MARK: - 2. 제출 (버튼 클릭 시)
    func submitAnswer(_ answer: String) {
        // View에서 인자로 넘어오는 answer를 self.userAnswer에 반영 (혹은 View가 이미 바인딩으로 업데이트했다면 생략 가능하지만 안전하게)
        self.userAnswer = answer
        guard !userAnswer.isEmpty else { return }
        
        // [Mock Mode]
        if isMockMode {
            checkMockAnswer()
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
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
    private func handleSubmissionResult(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        
        if isCorrect {
            self.feedbackMessage = "잘했어요!"
            
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
    
    // MARK: - Mock Helpers (Local Logic)
    private func setupMockData() {
        self.isLoading = true
        AsyncTask {
            try? await AsyncTask.sleep(nanoseconds: 500_000_000) // 로딩 흉내
            
            // 랜덤으로 문제 하나 선택
            if let randomProblem = self.problemPool.randomElement() {
                self.contentId = 999 // 가상의 ID
                self.questionText = randomProblem.question
                self.localCorrectAnswer = randomProblem.answer
                print("💻 [LOCAL] 테스트 문제 로드: \(randomProblem.question)")
            }
            
            self.isLoading = false
        }
    }
    
    private func checkMockAnswer() {
        // 공백 제거 등 전처리 (타이핑 미션이므로 띄어쓰기 중요하면 trimming만)
        let cleanAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCorrect = localCorrectAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let isCorrect = (cleanAnswer == cleanCorrect)
        
        handleSubmissionResult(isCorrect: isCorrect)
    }
}
