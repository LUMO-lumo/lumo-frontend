//
//  MissionModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/11/26.
//

import Foundation

// MARK: - 공통 응답 래퍼 (프로젝트 공통 구조에 맞춰 수정 필요)
struct BaseResponse<T: Codable>: Codable {
    let code: String
    let message: String
    let result: T?
    let success: Bool
}

// MARK: - 1. 미션 시작 (Response)
struct MissionStartResult: Codable {
    let contentId: Int
    let missionType: String // "NONE", "MATH" 등
    let difficulty: String  // "EASY" 등
    let question: String
    let answer: String?     // 클라이언트가 정답을 알 필요가 없다면 제외 가능
}

// MARK: - 2. 미션 답안 제출 (Request & Response)
struct MissionSubmitRequest: Codable {
    let contentId: Int
    let userAnswer: String
    let attemptCount: Int
}

struct MissionSubmitResult: Codable {
    let isCorrect: Bool
    let isCompleted: Bool
    let remainingQuestions: Int
    let message: String
}

// MARK: - 3. 알람 해제 (Request & Response)
struct DismissAlarmRequest: Codable {
    let alarmId: Int
    let dismissType: String // "MISSION"
    let snoozeCount: Int
}

struct DismissAlarmResult: Codable {
    let logId: Int
    let alarmId: Int
    let triggeredAt: String
    let dismissedAt: String
    let dismissType: String
    let snoozeCount: Int
}

struct DistanceMissionRequest: Codable {
    let contentId: Int
    let currentDistance: Double // 요청하신 부분
    let attemptCount: Int
}
