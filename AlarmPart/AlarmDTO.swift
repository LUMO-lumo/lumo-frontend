//
//  AlarmModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftData

// MARK: - Domain Model (App Internal Use)
// ✅ [필수] UserDefaults 저장을 위해 Codable 채택
struct Alarm: Identifiable, Codable {
    var id: UUID = UUID()
    var serverId: Int? = nil
    
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: [Int] // 0: Sun, 1: Mon, ..., 6: Sat
    var missionTitle: String
    var missionType: String
    
    var soundName: String = "기본음"
    
    // 기본 이니셜라이저 (기존 코드 호환)
    init(id: UUID = UUID(), serverId: Int? = nil, time: Date, label: String, isEnabled: Bool, repeatDays: [Int], missionTitle: String, missionType: String, soundName: String) {
        self.id = id
        self.serverId = serverId
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.missionTitle = missionTitle
        self.missionType = missionType
        self.soundName = soundName
    }
    
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
    // ✅ [수정] 서버 구조 변경 반영: 미션 설정 객체 추가
    let missionSetting: MissionSettingDTO?
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
    
    // ✅ [수정] 서버 DTO -> 로컬 Alarm 변환 (알람 목록 조회 시 사용)
    init(from dto: AlarmDTO) {
        self.id = UUID() // 로컬용 UUID 생성
        self.serverId = dto.alarmId
        self.label = dto.label ?? ""
        self.isEnabled = dto.isEnabled
        self.soundName = dto.soundType
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.time = formatter.date(from: dto.alarmTime) ?? Date()
        
        self.repeatDays = Alarm.convertRepeatDaysToInt(dto.repeatDays)
        
        // 미션 정보 매핑
        if let missionDTO = dto.missionSetting {
            switch missionDTO.missionType {
            case "CALCULATION":
                self.missionType = "계산"
                self.missionTitle = "수학문제"
            case "DICTATION":
                self.missionType = "받아쓰기"
                self.missionTitle = "따라쓰기"
            case "WALK":
                self.missionType = "운동"
                self.missionTitle = "거리미션"
            case "OX_QUIZ":
                self.missionType = "OX"
                self.missionTitle = "OX 퀴즈"
            default:
                self.missionType = "NONE"
                self.missionTitle = "미션 없음"
            }
        } else {
            self.missionTitle = "미션 정보 없음"
            self.missionType = "NONE"
        }
    }
    
    // ✅ [수정] 로컬 Alarm -> 서버 요청 Dictionary 변환 (알람 생성/수정 시 사용)
    func toDictionary() -> [String: Any] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // 생성/수정 시에는 미션 정보를 보내지 않거나 NONE으로 보냄
        let serverMissionType = "NONE"
        
        let missionSetting: [String: Any] = [
            "missionType": serverMissionType,
            "difficulty": "EASY",
            "walkGoalMeter": 0,
            "questionCount": 0
        ]
        
        let snoozeSetting: [String: Any] = [
            "isEnabled": true,
            "intervalSec": 0,
            "maxCount": 0
        ]
        
        return [
            "alarmTime": timeFormatter.string(from: self.time),
            "label": self.label,
            "soundType": self.soundName,
            "vibration": true,
            "volume": 100,
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
