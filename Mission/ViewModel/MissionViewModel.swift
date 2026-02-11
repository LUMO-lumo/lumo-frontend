//
//  MissionViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/11/26.
//

import Foundation
import Combine
import Moya

class MathMissionViewModel: ObservableObject {
    // MARK: - Properties
    private let provider = MoyaProvider<MissionTarget>()
    private var alarmId: Int
    private var contentId: Int? // 현재 풀고 있는 문제 ID
    private var attemptCount: Int = 0
    
    // MARK: - Published (UI State)
    @Published var questionText: String = "문제를 불러오는 중..."
    @Published var userAnswer: String = ""
    @Published var feedbackMessage: String = "" // "정답이에요!", "틀렸어요!"
    @Published var showFeedback: Bool = false   // 피드백 오버레이 표시 여부
    @Published var isCorrect: Bool = false      // 피드백 아이콘 (웃음/울음) 결정
    @Published var isMissionCompleted: Bool = false // 화면 전환용
    
    init(alarmId: Int) {
        self.alarmId = alarmId
    }
    
    // MARK: - API 1: 미션 시작 (문제 받아오기)
    func startMathMission() {
        provider.request(.startMission(alarmId: alarmId)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                do {
                    let decoded = try response.map(BaseResponse<MissionStartResult>.self)
                    if let data = decoded.result {
                        self.contentId = data.contentId
                        self.questionText = data.question
                        // Swagger 예시의 "88+33 = ?" 형식에 맞춤
                        // 만약 API가 "88+33"만 준다면 뒤에 " = ?" 붙이는 처리 필요
                    }
                } catch {
                    print("Decoding Error: \(error)")
                }
            case .failure(let error):
                print("Network Error: \(error)")
            }
        }
    }
    
    // MARK: - API 2: 답안 제출
    func submitAnswer() {
        guard let contentId = contentId, !userAnswer.isEmpty else { return }
        
        attemptCount += 1
        let request = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: userAnswer,
            attemptCount: attemptCount
        )
        
        provider.request(.submitMission(alarmId: alarmId, request: request)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                do {
                    let decoded = try response.map(BaseResponse<MissionSubmitResult>.self)
                    if let data = decoded.result {
                        self.handleSubmissionResult(data)
                    }
                } catch {
                    print("Decoding Error: \(error)")
                }
            case .failure(let error):
                print("Network Error: \(error)")
            }
        }
    }
    
    // 결과 처리 로직
    private func handleSubmissionResult(_ result: MissionSubmitResult) {
        self.isCorrect = result.isCorrect
        self.showFeedback = true
        
        if result.isCorrect {
            self.feedbackMessage = "정답이에요!"
            // 정답인 경우 잠시 후 알람 해제 요청 혹은 다음 로직 수행
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if result.isCompleted {
                    self.dismissAlarm()
                } else {
                    // 문제가 더 남아있다면 다음 문제 로직 (현재 API상으로는 start 다시 호출? 혹은 배열로 받는지 확인 필요)
                    // 여기서는 완료로 가정
                }
            }
        } else {
            self.feedbackMessage = "틀렸어요!"
            // 틀린 경우 일정 시간 후 피드백 닫고 재시도 유도
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showFeedback = false
                self.userAnswer = "" // 입력창 초기화
            }
        }
    }
    
    // MARK: - API 3: 알람 해제 (최종 완료)
    private func dismissAlarm() {
        let request = DismissAlarmRequest(
            alarmId: alarmId,
            dismissType: "MISSION",
            snoozeCount: 0 // 필요 시 관리하는 스누즈 카운트 전달
        )
        
        provider.request(.dismissAlarm(alarmId: alarmId, request: request)) { [weak self] result in
            switch result {
            case .success:
                print("알람 해제 성공")
                self?.isMissionCompleted = true
            case .failure(let error):
                print("해제 실패: \(error)")
            }
        }
    }
}
