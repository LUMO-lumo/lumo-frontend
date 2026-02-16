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
    var repeatDays: [Int]
    var missionTitle: String
    var missionType: String
    
    // 앱 내부에서는 '한국어' 이름 사용 ("비명 소리")
    var soundName: String = "기본음"
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    static let dummyData: [Alarm] = [
        Alarm(time: Date(), label: "테스트", isEnabled: true, repeatDays: [], missionTitle: "테스트", missionType: "NONE")
    ]
}

// MARK: - DTO Definitions (API Models - Response)
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

// MARK: - Request DTOs (서버 요청용 구조체)
struct CreateAlarmRequest: Encodable {
    let alarmTime: String
    let label: String
    let isEnabled: Bool
    let soundType: String
    let vibration: Bool
    let volume: Int
    let repeatDays: [String]
    let snoozeSetting: SnoozeRequest
    let missionSetting: MissionRequest
}

struct SnoozeRequest: Encodable {
    let isEnabled: Bool
    let intervalSec: Int
    let maxCount: Int
}

struct MissionRequest: Encodable {
    let missionType: String
    let difficulty: String
    let walkGoalMeter: Int
    let questionCount: Int
}

// MARK: - Extensions (Mapping Logic)
extension Alarm {
    
    // ✅ 한글 이름 <-> 서버용 실제 파일명 매핑
    private static let soundMapping: [String: String] = [
        "비명 소리": "scream14-6918",
        "천둥 번개": "big-thunder-34626",
        "개 짖는 소리": "big-dog-barking-112717",
        "절규": "desperate-shout-106691",
        "뱃고동": "traimory-mega-horn-angry-siren-f-cinematic-trailer-sound-effects-193408",
        "평온한 멜로디": "calming-melody-loop-291840",
        "섬의 아침": "the-island-clearing-216263",
        "플루트 연주": "native-american-style-flute-music-324301",
        "종소리": "calm-music-64526",
        "소원": "i-wish-looping-tune-225553",
        "환희의 록": "rock-of-joy-197159",
        "황제": "emperor-197164",
        "비트 앤 베이스": "basic-beats-and-bass-10791",
        "침묵 속 노력": "work-hard-in-silence-spoken-201870",
        "런어웨이": "runaway-loop-373063",
        "기본음": "scream14-6918"
    ]
    
    // DTO -> Alarm (서버 데이터를 앱 모델로)
    init(from dto: AlarmDTO) {
        self.serverId = dto.alarmId
        self.label = dto.label ?? ""
        self.isEnabled = dto.isEnabled
        
        let foundKey = Alarm.soundMapping.first { $0.value == dto.soundType }?.key
        self.soundName = foundKey ?? "기본음"
        
        // 시간 파싱 (HH:mm:ss 또는 HH:mm 모두 대응)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: dto.alarmTime) {
            self.time = date
        } else {
            formatter.dateFormat = "HH:mm"
            self.time = formatter.date(from: dto.alarmTime) ?? Date()
        }
        
        self.repeatDays = Alarm.convertRepeatDaysToInt(dto.repeatDays)
        
        if let mission = dto.missionSetting {
            self.missionType = mission.missionType
            switch mission.missionType {
            case "CALCULATION": self.missionTitle = "수학문제"
            case "DICTATION": self.missionTitle = "따라쓰기"
            case "WALK": self.missionTitle = "거리미션"
            case "OX": self.missionTitle = "OX 퀴즈"
            default: self.missionTitle = "미션 없음"
            }
        } else {
            self.missionTitle = "미션 정보 없음"
            self.missionType = "NONE"
        }
    }
    
    // Alarm -> Dictionary (앱 모델을 서버 요청 데이터로)
    func toDictionary() -> [String: Any] {
        let timeFormatter = DateFormatter()
        // 🚨 [수정] 다시 "HH:mm"으로 복구 + Locale 설정
        // 1. Locale을 설정해야 사용자 폰 설정(12시간제 등)에 영향받지 않고 정확한 "14:30" 형식이 나옵니다.
        // 2. 서버가 "HH:mm:ss"가 아닌 "HH:mm"을 원할 가능성이 매우 높습니다.
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"
        
        let serverMissionType: String
        switch self.missionType {
        case "계산", "수학문제": serverMissionType = "CALCULATION"
        case "받아쓰기", "따라쓰기": serverMissionType = "DICTATION"
        case "운동", "거리미션": serverMissionType = "WALK"
        case "OX", "OX 퀴즈": serverMissionType = "OX"
        default: serverMissionType = "NONE"
        }
        
        let serverSoundType = Alarm.soundMapping[self.soundName] ?? "scream14-6918"
        
        // ✅ [유지] 수동 Dictionary 생성 (Bool 타입 보장)
        let dict: [String: Any] = [
            "alarmTime": timeFormatter.string(from: self.time),
            "label": self.label,
            "isEnabled": self.isEnabled,
            "soundType": serverSoundType,
            "vibration": true,
            "volume": 100,
            "repeatDays": Alarm.convertRepeatDaysToString(self.repeatDays),
            "snoozeSetting": [
                "isEnabled": true,
                "intervalSec": 300,
                "maxCount": 3
            ] as [String: Any],
            "missionSetting": [
                "missionType": serverMissionType,
                "difficulty": "EASY",
                "walkGoalMeter": serverMissionType == "WALK" ? 50 : 0,
                "questionCount": 3
            ] as [String: Any]
        ]
        
        return dict
    }
    
    static func convertRepeatDaysToInt(_ days: [String]) -> [Int] {
        let dayMap: [String: Int] = ["SUN": 0, "MON": 1, "TUE": 2, "WED": 3, "THU": 4, "FRI": 5, "SAT": 6]
        return days.compactMap { dayMap[$0] }.sorted()
    }
    
    static func convertRepeatDaysToString(_ days: [Int]) -> [String] {
        let dayMap: [Int: String] = [0: "SUN", 1: "MON", 2: "TUE", 3: "WED", 4: "THU", 5: "FRI", 6: "SAT"]
        return days.compactMap { dayMap[$0] }
    }
}
