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
    
    var soundName: String? = "기본음"
    
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
    
    // 1. 서버 DTO -> 앱 모델 변환 (GET)
    init(from dto: AlarmDTO) {
        self.serverId = dto.alarmId
        self.label = dto.label ?? ""
        self.isEnabled = dto.isEnabled
        self.soundName = dto.soundType
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 서버는 초 단위 없음
        self.time = formatter.date(from: dto.alarmTime) ?? Date()
        
        self.repeatDays = Alarm.convertRepeatDaysToInt(dto.repeatDays)
        
        // ⚠️ 주의: 현재는 서버에서 받아온 미션을 앱에 반영하는 로직이 없어서 'NONE'으로 고정되어 있습니다.
        // 추후 서버의 MissionSettingDTO를 해석해서 missionType을 설정하는 로직 추가가 필요합니다.
        self.missionTitle = "미션 정보 없음"
        self.missionType = "NONE"
    }
    
    // 2. 앱 모델 -> 서버 DTO 변환 (POST/PUT)
    // ✅ [수정 완료] 사용자가 선택한 미션 타입과 설정을 동적으로 반영
    //    func toDictionary() -> [String: Any] {
    //        let timeFormatter = DateFormatter()
    //        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
    //        timeFormatter.dateFormat = "HH:mm" // 🚨 서버가 요구하는 "시:분" 포맷
    //
    //        // 1. 미션 타입 매핑 (한글 -> 서버 코드)
    ////        let serverMissionType: String
    ////        switch self.missionType {
    ////        case "계산", "수학문제", "CALCULATION": serverMissionType = "CALCULATION"
    ////        case "받아쓰기", "따라쓰기", "DICTATION": serverMissionType = "DICTATION"
    ////        case "운동", "거리미션", "WALK": serverMissionType = "WALK"
    ////        case "OX", "OX 퀴즈", "OX_QUIZ": serverMissionType = "OX"
    ////        default: serverMissionType = "NONE"
    ////        }
    //
    //        // 2. 미션별 세부 설정값 결정 (기본값 적용)
    ////        let questionCount: Int
    ////        let walkGoalMeter: Int
    ////
    ////        if serverMissionType == "CALCULATION" || serverMissionType == "OX" || serverMissionType == "DICTATION" {
    ////            questionCount = 3
    ////            walkGoalMeter = 0
    ////        } else if serverMissionType == "WALK" {
    ////            questionCount = 0
    ////            walkGoalMeter = 50
    ////        } else {
    ////            questionCount = 0
    ////            walkGoalMeter = 0
    ////        }
    //
    //        // 3. 미션 설정 객체 생성
    //        let missionSetting: [String: Any] = [
    //            "missionType": serverMissionType,
    //            "difficulty": "EASY",
    //            "walkGoalMeter": walkGoalMeter,
    //            "questionCount": questionCount
    //        ]
    //
    //        // 4. 스누즈 설정
    //        let snoozeSetting: [String: Any] = [
    //            "isEnabled": true,
    //            "intervalSec": 300,
    //            "maxCount": 3
    //        ]
    //
    //        // 5. 사운드 이름 처리 (서버 호환성용 안전장치)
    //        // '기본음' 등의 한글 이름이 들어가면 서버 에러 가능성이 있어 테스트용 ID로 대체
    //        let serverSoundType = (self.soundName == "기본음" || self.soundName.isEmpty) ? "scream14-6918" : self.soundName
    //
    //        // 6. 요일 안전 처리 (빈 배열 방지)
    //        let dayStrings = Alarm.convertRepeatDaysToString(self.repeatDays)
    //        let safeRepeatDays = dayStrings.isEmpty ? ["MON"] : dayStrings
    //
    //        // 7. 최종 딕셔너리 반환
    //        return [
    //            "alarmTime": timeFormatter.string(from: self.time),
    //            "label": self.label.isEmpty ? "Alarm" : self.label,
    //            "isEnabled": self.isEnabled,
    //            "soundType": serverSoundType,
    //            "vibration": true,
    //            "volume": 100,
    //            "repeatDays": safeRepeatDays,
    //            "snoozeSetting": snoozeSetting,
    //            "missionSetting": missionSetting
    //        ]
    //    }
    //
    //    static func convertRepeatDaysToInt(_ days: [String]) -> [Int] {
    //        let dayMap: [String: Int] = [
    //            "SUN": 0, "MON": 1, "TUE": 2, "WED": 3, "THU": 4, "FRI": 5, "SAT": 6
    //        ]
    //        return days.compactMap { dayMap[$0] }.sorted()
    //    }
    //
    //    static func convertRepeatDaysToString(_ days: [Int]) -> [String] {
    //        let dayMap: [Int: String] = [
    //            0: "SUN", 1: "MON", 2: "TUE", 3: "WED", 4: "THU", 5: "FRI", 6: "SAT"
    //        ]
    //        return days.sorted().compactMap { dayMap[$0] }
    //    }
    //}
    
    func toDictionary() -> [String: Any] {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"
        
        // 1. 미션 설정 강제 고정 (NONE / 0 / 0)
        let serverMissionType = "NONE"
        let questionCount = 0
        let walkGoalMeter = 0
        
        let missionSetting: [String: Any] = [
            "missionType": serverMissionType, // "NONE"
            "difficulty": "EASY",
            "walkGoalMeter": walkGoalMeter,   // 0
            "questionCount": questionCount    // 0
        ]
        
        // 2. 스누즈 설정
        let snoozeSetting: [String: Any] = [
            "isEnabled": true,
            "intervalSec": 300,
            "maxCount": 3
        ]
        
        // 3. 사운드 이름 처리
        let currentSound = self.soundName ?? "기본음"
        let serverSoundType = (currentSound == "기본음" || currentSound.isEmpty) ? "scream14-6918" : currentSound
        
        // 4. 요일 안전 처리
        let dayStrings = Alarm.convertRepeatDaysToString(self.repeatDays)
        let safeRepeatDays = dayStrings.isEmpty ? ["MON"] : dayStrings
        
        // 5. 최종 반환
        return [
            "alarmTime": timeFormatter.string(from: self.time),
            "label": self.label.isEmpty ? "Alarm" : self.label,
            "isEnabled": self.isEnabled,
            "soundType": serverSoundType,
            "vibration": true,
            "volume": 100,
            "repeatDays": safeRepeatDays,
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
