//
//  OXMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Combine
import SwiftUI
import Moya

// 로컬 테스트용 문제 모델
struct LocalOXProblem {
    let question: String
    let answer: String // "O" 또는 "X"
}

@MainActor
class OXMissionViewModel: BaseMissionViewModel {
    
    // MARK: - Configuration
    // ⭐️ 이 값을 false로 바꾸면 API 모드로 작동합니다.
    private var isMockMode: Bool
    
    // MARK: - UI Properties
    @Published var questionText: String = "로딩 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false     // 정답 이미지 표시용
    
    // OX 전용 프로퍼티
    let alarmLabel: String
    
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
    init(alarmId: Int, alarmLabel: String) {
        self.alarmLabel = alarmLabel
        
        // ✅ [핵심] ID가 -1이면 테스트 모드(Mock)로 강제 설정
        self.isMockMode = (alarmId == -1)
        
        super.init(alarmId: alarmId)
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func startOXMission() {
        // [Mock Mode] 강제 로컬 모드일 경우
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real API Mode]
        AsyncTask {
            self.isLoading = true
            
            do {
                print("🚀 [SERVER] OX 미션 시작 요청...")
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
                
                self.isMockMode = true
                
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
    // View에서 "O" 또는 "X" 스트링을 넘겨준다고 가정
    func submitAnswer(_ answer: String) {
        // View에서 인자로 넘어오는 answer를 self.userAnswer에 반영
        self.userAnswer = answer
        
        // [Mock Mode]
        if isMockMode {
            checkMockAnswer()
            return
        }
        
        // [Real API Mode] - 기존 코드 보존
        guard let contentId = contentId else {
            print("❌ contentId 없음")
            return
        }
        
        // 보낼 데이터 준비
        let request = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: userAnswer,
            attemptCount: self.attemptCount + 1
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
    
    // MARK: - Helper (UI Logic)
    private func handleSubmissionResult(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        
        if isCorrect {
            // ✅ 정답일 때
            self.feedbackMessage = "정답이에요!"
            
            // Mock 모드일 때는 수동으로 완료 처리
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
        // 1️⃣ UI 표시용: MissionError 처리
        if let missionError = error as? MissionError {
            switch missionError {
            case .serverError(let message):
                self.errorMessage = message
            }
        } else {
            self.errorMessage = "오류가 발생했습니다."
        }
        
        // 2️⃣ 디버깅용: 서버 응답 바디(Body) 뜯어보기 🕵️
        // 일반 Error를 MoyaError로 변환 시도
        if let moyaError = error as? MoyaError {
            if let response = moyaError.response {
                // 서버가 보낸 실제 응답 데이터 (JSON)를 문자열로 변환
                let errorBody = String(data: response.data, encoding: .utf8) ?? "데이터 없음"
                print("❌ [DEBUG] 서버 응답 코드: \(response.statusCode)")
                print("❌ [DEBUG] 서버 에러 바디: \(errorBody)")
            } else {
                print("❌ [DEBUG] Moya 에러지만 응답 본문이 없음: \(moyaError)")
            }
        } else {
            // Moya 에러도 아님 (완전 시스템 에러 등)
            print("❌ Error: \(error.localizedDescription)")
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
    
    private func checkMockAnswer() {
        AsyncTask {
            // 통신 흉내 (너무 빠르면 어색하므로 약간 딜레이)
            try? await AsyncTask.sleep(nanoseconds: 300_000_000)
            
            // "O" 또는 "X" 비교
            let isCorrect = (self.userAnswer == self.localCorrectAnswer)
            self.handleSubmissionResult(isCorrect: isCorrect)
        }
    }
}
