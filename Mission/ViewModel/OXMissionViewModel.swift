//
//  OXMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Combine
import SwiftUI // withAnimation 사용을 위해 필요

class OXMissionViewModel: BaseMissionViewModel {
    
    @Published var questionText: String = "로딩 중..."
    @Published var isWrongAnswer: Bool = false // 흔들기 효과용
    
    // 1. 시작
    func start() async {
            print("🚀 [OX] 미션 시작 요청")
            do {
                // 부모의 startMission 호출 (await 사용)
                if let result = try await super.startMission() {
                    self.questionText = result.question
                    print("🌐 [SERVER] 문제 로드 성공: \(result.question)")
                }
            } catch {
                print("❌ [SERVER] 문제 로드 실패: \(error)")
                self.questionText = "문제를 불러올 수 없습니다."
                self.errorMessage = "네트워크 연결을 확인해주세요."
            }
        }
    // 2. 제출 (버튼 클릭 시)
    func submitAnswer(_ answer: String) async {
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
            
            do {
                // 부모의 submitMission 호출 (await 사용)
                let isCorrect = try await super.submitMission(request: request)
                
                if isCorrect {
                    print("🎉 정답!")
                    self.isMissionCompleted = true
                } else {
                    print("❌ 오답")
                    self.triggerShake()
                }
            } catch {
                print("❌ 제출 중 에러 발생: \(error)")
                self.errorMessage = "전송 실패. 다시 시도해주세요."
            }
        }
    
    private func triggerShake() {
            withAnimation(.default) {
                isWrongAnswer = true
            }
            // 0.4초 후 다시 원상복구 (MainActor이므로 안전)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isWrongAnswer = false
            }
        }
}
