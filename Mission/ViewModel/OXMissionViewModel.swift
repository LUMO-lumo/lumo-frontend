//
//  OXMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Combine
import SwiftUI

// 로컬 테스트용 문제 모델
struct LocalOXProblem {
    let question: String
    let answer: String // "O" 또는 "X"
}

@MainActor
class OXMissionViewModel: BaseMissionViewModel {
    
    // MARK: - Configuration
    // ⭐️ 이 값을 false로 바꾸면 API 모드로 작동합니다.
    private let isMockMode: Bool = true
    
    // MARK: - UI Properties
    @Published var questionText: String = "로딩 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false     // 정답 이미지 표시용
    
    // 로컬 정답 확인용
    private var localCorrectAnswer: String = ""
    
    // MARK: - 🚨 Local Mock Data Pool (요청하신 데이터)
    private let problemPool: [LocalOXProblem] = [
        LocalOXProblem(question: "한국의 국화는 무궁화이다", answer: "O"),
        LocalOXProblem(question: "세종대왕은 한글을 만들었다", answer: "O"),
        LocalOXProblem(question: "광합성은 밤에 일어난다", answer: "X"),
        LocalOXProblem(question: "남극은 북극보다 춥다", answer: "O"),
        LocalOXProblem(question: "박쥐는 새의 한 종류이다", answer: "X"),
        LocalOXProblem(question: "독도는 한국 영토이다", answer: "O"),
        LocalOXProblem(question: "거북이는 파충류이다", answer: "O"),
        LocalOXProblem(question: "고래는 물고기다", answer: "X"),
        LocalOXProblem(question: "한반도는 아시아에 있다", answer: "O"),
        LocalOXProblem(question: "토마토는 채소이다", answer: "X")
    ]
    
    // MARK: - Initialization
    override init(alarmId: Int = 1) {
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func startOXMission() {
        // [Mock Mode]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
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
    // View에서 "O" 또는 "X" 스트링을 넘겨준다고 가정
    func submitAnswer(_ answer: String) {
        // [Mock Mode]
        if isMockMode {
            checkMockAnswer(userAnswer: answer)
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
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
            // ✅ 정답일 때
            self.feedbackMessage = "정답이에요!"
            print("🎉 정답입니다!")
            
            // Mock 모드일 때는 수동으로 완료 처리
            if isMockMode {
                AsyncTask {
                    try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                    self.isMissionCompleted = true
                }
            } else {
                // API 모드에서는 BaseViewModel이 dismissAlarm 성공 시 isMissionCompleted = true 처리
            }
            
        } else {
            // ❌ 오답일 때
            self.feedbackMessage = "틀렸어요!"
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.showFeedback = false
                self.userAnswer = ""
            }
        }
    }
    
    // MARK: - Mock Helpers (Local Logic)
    private func setupMockData() {
        self.isLoading = true
        AsyncTask {
            try? await AsyncTask.sleep(nanoseconds: 500_000_000) // 로딩 흉내
            
            // 랜덤으로 문제 하나 선택
            if let randomProblem = self.problemPool.randomElement() {
                self.contentId = 999
                self.questionText = randomProblem.question
                self.localCorrectAnswer = randomProblem.answer
                print("💻 [LOCAL] OX 문제 로드: \(randomProblem.question) (정답: \(randomProblem.answer))")
            }
            
            self.isLoading = false
        }
    }
    
    private func checkMockAnswer(userAnswer: String) {
        AsyncTask {
            // 통신 흉내
            try? await AsyncTask.sleep(nanoseconds: 300_000_000)
            
            // "O" 또는 "X" 비교
            let isCorrect = (userAnswer == self.localCorrectAnswer)
            self.handleSubmissionResult(isCorrect: isCorrect)
        }
    }
}
