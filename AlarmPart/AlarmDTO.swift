//
//  AlarmModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftData

// MARK: - Domain Model (App Internal Use)

struct Alarm: Identifiable, Codable {
    var id: UUID = UUID()
    var serverId: Int? = nil
    
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: [Int] // 0: Sun, 1: Mon, ..., 6: Sat
    var missionTitle: String
    var missionType: String
    
    var soundName: String? = "기본음"
    
    init(
        id: UUID = UUID(),
        serverId: Int? = nil,
        time: Date,
        label: String,
        isEnabled: Bool,
        repeatDays: [Int],
        missionTitle: String,
        missionType: String,
        soundName: String
    ) {
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

struct MissionStartResponse: Codable {
    let code: String?
    let message: String?
    let result: [MissionContentDTO]
    let success: Bool?
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
        "런어웨이": "runaway-loop-373063"
    ]
    
    // 한글 이름 -> 파일명 (서버 전송용)
    static func toServerSoundName(_ displayName: String) -> String {
        return soundMapping[displayName] ?? "scream14-6918" // 기본값: 비명소리
    }
    
    // 파일명 -> 한글 이름 (UI 표시용)
    static func fromServerSoundName(_ fileName: String) -> String {
        // 1. 정확한 매칭
        if let key = soundMapping.first(where: { $0.value == fileName })?.key {
            return key
        }
        
        // 2. 확장자 제거 후 매칭 (서버가 .mp3 등을 붙여서 줄 경우 대비)
        // 예: "scream14-6918.mp3" -> "scream14-6918"
        let nameWithoutExt = fileName.components(separatedBy: ".").first ?? fileName
        if let key = soundMapping.first(where: { $0.value == nameWithoutExt })?.key {
            return key
        }
        
        return "비명 소리"
    }
    
    init(from dto: AlarmDTO) {
        self.id = UUID() // 로컬용 UUID 생성
        self.serverId = dto.alarmId
        self.label = dto.label ?? ""
        self.isEnabled = dto.isEnabled
        
        // 서버의 파일명(영어)을 한글 이름으로 변환하여 UI에 저장
        self.soundName = Alarm.fromServerSoundName(dto.soundType)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 서버는 초 단위 없음
        self.time = formatter.date(from: dto.alarmTime) ?? Date()
        
        self.repeatDays = Alarm.convertRepeatDaysToInt(dto.repeatDays)
        
        if let settings = dto.missionSetting {
            switch settings.missionType {
            case "MATH", "CALCULATION":
                self.missionType = "계산"
                self.missionTitle = "수학 문제 풀기"
                
            case "TYPING", "DICTATION":
                self.missionType = "받아쓰기"
                self.missionTitle = "명언 따라쓰기"
                
            case "WALK", "DISTANCE":
                self.missionType = "운동"
                let goal = settings.walkGoalMeter
                self.missionTitle = "목표 거리 걷기 (\(goal)m)"
                
            case "OX", "OX_QUIZ", "QUIZ":
                self.missionType = "OX"
                self.missionTitle = "시사 상식 퀴즈"
                
            default:
                self.missionType = "계산" // 기본값
                self.missionTitle = "수학 문제 풀기"
            }
        } else {
            self.missionType = "NONE"
            self.missionTitle = "미션 없음"
        }
    }
    
    func toDictionary() -> [String: Any] {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"
        
        var serverMissionType = "NONE"
        var questionCount = 0
        var walkGoalMeter = 0
        
        // 저장된 난이도 불러오기 (없으면 MEDIUM 기본값)
        let savedDifficulty = UserDefaults.standard.string(forKey: "MISSION_DIFFICULTY") ?? "MEDIUM"
        var serverDifficulty = "MEDIUM"
        
        switch savedDifficulty {
        case "LOW":
            serverDifficulty = "EASY"
        case "MEDIUM":
            serverDifficulty = "MEDIUM"
        case "HIGH":
            serverDifficulty = "HARD"
        default:
            serverDifficulty = "MEDIUM"
        }
        
        switch self.missionType {
        case "계산":
            serverMissionType = "MATH"
            questionCount = 1 // 기본값 (나중에 UI에서 설정 가능하게 변경 필요)
            
        case "받아쓰기":
            serverMissionType = "TYPING"
            questionCount = 1
            
        case "운동":
            serverMissionType = "WALK"
            walkGoalMeter = 50 // 기본 50걸음
            
        case "OX", "퀴즈", "시사":
            serverMissionType = "OX_QUIZ"
            questionCount = 1
            
        default:
            serverMissionType = "MATH"
        }
        
        if (serverMissionType == "OX_QUIZ" || serverMissionType == "TYPING") && serverDifficulty == "HARD" {
            print("⚠️ [Warning] \(serverMissionType)는 HARD 난이도가 없어 MEDIUM으로 하향 조정합니다.")
            serverDifficulty = "MEDIUM"
        }
        
        print("📤 미션 변환: \(self.missionType) -> \(serverMissionType)")
        
        let missionSetting: [String: Any] = [
            "missionType": serverMissionType,
            "difficulty": serverDifficulty,
            "walkGoalMeter": walkGoalMeter,
            "questionCount": questionCount
        ]
        
        // 2. 스누즈 설정
        let snoozeSetting: [String: Any] = [
            "isEnabled": true,
            "intervalSec": 300,
            "maxCount": 3
        ]
        
        // 3. 사운드 이름 처리
        // 한글 이름(UI)을 파일명(Server)으로 변환
        let currentDisplaySound = self.soundName ?? "기본음"
        let serverSoundType = Alarm.toServerSoundName(currentDisplaySound)
        
        // 4. 요일 안전 처리
        let dayStrings = Alarm.convertRepeatDaysToString(self.repeatDays)
        let safeRepeatDays = dayStrings.isEmpty ? ["MON"] : dayStrings
        
        // 5. 최종 반환
        return [
            "alarmTime": timeFormatter.string(from: self.time),
            "label": self.label.isEmpty ? "Alarm" : self.label,
            "isEnabled": self.isEnabled,
            "soundType": serverSoundType, //파일명(영어)만 전송. soundId/soundName 등 불필요한 키 제거.
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
