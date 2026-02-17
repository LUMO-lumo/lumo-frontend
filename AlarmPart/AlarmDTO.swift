//
//  AlarmModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftData

// MARK: - Domain Model (App Internal Use)
struct Alarm: Identifiable {
    let id: UUID = UUID()
    var serverId: Int? = nil
    
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: [Int] // 0: Sun, 1: Mon, ..., 6: Sat
    var missionTitle: String
    var missionType: String
    
    var soundName: String = "기본음"
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    static let dummyData: [Alarm] = [
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
            label: "새벽 기상",
            isEnabled: true,
            repeatDays: [1, 2, 3, 4, 5],
            missionTitle: "물 한잔 마시기",
            missionType: "건강",
            soundName: "커피한잔의 여유"
        )
    ]
}

// MARK: - DTO Definitions (API Models)

struct AlarmDTO: Codable {
    let alarmId: Int
    let alarmTime: String
    let label: String?
    let isEnabled: Bool
    let soundType: String
    let vibration: Bool
    let volume: Int
    let repeatDays: [String]
    let snoozeSetting: SnoozeSettingDTO?
}

struct SnoozeSettingDTO: Codable {
    let snoozeId: Int?
    let isEnabled: Bool?
    let intervalSec: Int?
    let maxCount: Int?
}

struct MissionSettingDTO: Codable {
    let missionType: String
    let difficulty: String
    let walkGoalMeter: Int
    let questionCount: Int
}

struct MissionContentDTO: Codable {
    let contentId: Int
    let missionType: String
    let difficulty: String
    let question: String?
    let answer: String?
}

struct MissionSubmitResultDTO: Codable {
    let isCorrect: Bool
    let isCompleted: Bool
    let remainingQuestions: Int
    let message: String?
}

struct WalkMissionResultDTO: Codable {
    let goalDistance: Int
    let currentDistance: Double
    let progressPercentage: Double
    let isCompleted: Bool
}

struct AlarmLogDTO: Codable {
    let logId: Int
    let alarmId: Int
    let triggeredAt: String
    let dismissedAt: String?
    let dismissType: String?
    let snoozeCount: Int
}

struct MissionHistoryDTO: Codable {
    let historyId: Int
    let alarmId: Int
    let missionType: String
    let isSuccess: Bool
    let attemptCount: Int
    let completedAt: String
}

struct AlarmSoundDTO: Codable {
    let soundId: String
    let displayName: String
    let isDefault: Bool
}

// MARK: - Extensions (Mapping Logic)
extension Alarm {
    
    init(from dto: AlarmDTO) {
        self.serverId = dto.alarmId
        self.label = dto.label ?? ""
        self.isEnabled = dto.isEnabled
        self.soundName = dto.soundType
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.time = formatter.date(from: dto.alarmTime) ?? Date()
        
        self.repeatDays = Alarm.convertRepeatDaysToInt(dto.repeatDays)
        
        self.missionTitle = "미션 정보 없음"
        self.missionType = "NONE"
    }
    
    // ✅ [핵심 수정] 요청하신 포맷과 완벽히 일치하도록 구성
    func toDictionary() -> [String: Any] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // 1. 미션 타입 매핑
        // ✅ 요청하신 대로 미션 타입을 무조건 "NONE"으로 설정하여 전송
        let serverMissionType = "NONE"
        
        /* 기존 매핑 로직 주석 처리 (필요시 복구 가능)
        switch self.missionType {
        case "계산": serverMissionType = "CALCULATION"
        case "받아쓰기": serverMissionType = "DICTATION"
        case "운동": serverMissionType = "WALK"
        case "OX": serverMissionType = "OX_QUIZ"
        default: serverMissionType = "NONE"
        }
        */
        
        // 2. 미션 설정 (요청하신 예시: missionType -> difficulty -> walkGoalMeter:0 -> questionCount:0)
        let missionSetting: [String: Any] = [
            "missionType": serverMissionType, // 항상 "NONE" 전송
            "difficulty": "EASY",
            "walkGoalMeter": 0,    // 요청값 0
            "questionCount": 0     // 요청값 0
        ]
        
        // 3. 스누즈 설정 (요청하신 예시: isEnabled -> intervalSec:0 -> maxCount:0)
        let snoozeSetting: [String: Any] = [
            "isEnabled": true,
            "intervalSec": 0,      // 요청값 0
            "maxCount": 0          // 요청값 0
        ]
        
        // 4. 전체 데이터 구조 (요청하신 순서 반영)
        return [
            "alarmTime": timeFormatter.string(from: self.time),
            "label": self.label,
            "soundType": self.soundName, // 서버가 받는 String 값
            "vibration": true,
            "volume": 100, // 요청값 100
            "repeatDays": Alarm.convertRepeatDaysToString(self.repeatDays),
            "snoozeSetting": snoozeSetting,
            "missionSetting": missionSetting
        ]
    }
    
    static func convertRepeatDaysToInt(_ days: [String]) -> [Int] {
        let dayMap: [String: Int] = [
            "SUN": 0, "MON": 1, "TUE": 2, "WED": 3, "THU": 4, "FRI": 5, "SAT": 6
        ]
        return days.compactMap { dayMap[$0] }.sorted()
    }
    
    static func convertRepeatDaysToString(_ days: [Int]) -> [String] {
        let dayMap: [Int: String] = [
            0: "SUN", 1: "MON", 2: "TUE", 3: "WED", 4: "THU", 5: "FRI", 6: "SAT"
        ]
        return days.sorted().compactMap { dayMap[$0] }
    }
}
