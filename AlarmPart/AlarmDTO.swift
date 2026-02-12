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
    
    // [중요] 서버 DB와 연동을 위한 ID (이게 있어야 수정/삭제 가능)
    var serverId: Int? = nil
    
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: [Int] // 0: Sun, 1: Mon, ..., 6: Sat
    var missionTitle: String
    var missionType: String
    
    // 사운드 이름 저장
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
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            label: "아침 기상",
            isEnabled: true,
            repeatDays: [1, 3, 5],
            missionTitle: "수학 5문제 풀기",
            missionType: "계산",
            soundName: "사이렌"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date(),
            label: "영어 단어 암기",
            isEnabled: false,
            repeatDays: [2, 4],
            missionTitle: "영어 단어 10개 쓰기",
            missionType: "받아쓰기"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
            label: "운동 가기",
            isEnabled: true,
            repeatDays: [0, 6],
            missionTitle: "스쿼트 20회",
            missionType: "운동"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date(),
            label: "점심 약 먹기",
            isEnabled: true,
            repeatDays: [0, 1, 2, 3, 4, 5, 6],
            missionTitle: "비타민 챙겨먹기",
            missionType: "건강"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date(),
            label: "코딩 공부",
            isEnabled: true,
            repeatDays: [1, 3, 5],
            missionTitle: "알고리즘 1문제",
            missionType: "공부"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? Date(),
            label: "저녁 준비",
            isEnabled: false,
            repeatDays: [0, 1, 2, 3, 4, 5, 6],
            missionTitle: "장보기 리스트 확인",
            missionType: "생활"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date(),
            label: "하루 마무리",
            isEnabled: true,
            repeatDays: [0, 1, 2, 3, 4, 5, 6],
            missionTitle: "일기 쓰기",
            missionType: "기록"
        )
    ]
}

// MARK: - DTO Definitions (API Models)
// [복구 완료] 서버 통신에 필요한 DTO 구조체들을 다시 정의했습니다.

/// 알람 기본 정보 DTO
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

/// 스누즈 설정 DTO
struct SnoozeSettingDTO: Codable {
    let snoozeId: Int?
    let isEnabled: Bool?
    let intervalSec: Int?
    let maxCount: Int?
}

/// 미션 설정 DTO
struct MissionSettingDTO: Codable {
    let missionType: String
    let difficulty: String
    let walkGoalMeter: Int
    let questionCount: Int
}

/// 미션 컨텐츠(문제) DTO
struct MissionContentDTO: Codable {
    let contentId: Int
    let missionType: String
    let difficulty: String
    let question: String?
    let answer: String?
}

/// 미션 제출 결과 DTO
struct MissionSubmitResultDTO: Codable {
    let isCorrect: Bool
    let isCompleted: Bool
    let remainingQuestions: Int
    let message: String?
}

/// 걷기 미션 결과 DTO
struct WalkMissionResultDTO: Codable {
    let goalDistance: Int
    let currentDistance: Double
    let progressPercentage: Double
    let isCompleted: Bool
}

/// 알람 로그 DTO
struct AlarmLogDTO: Codable {
    let logId: Int
    let alarmId: Int
    let triggeredAt: String
    let dismissedAt: String?
    let dismissType: String?
    let snoozeCount: Int
}

/// 미션 수행 기록 DTO
struct MissionHistoryDTO: Codable {
    let historyId: Int
    let alarmId: Int
    let missionType: String
    let isSuccess: Bool
    let attemptCount: Int
    let completedAt: String
}

/// 알람 사운드 목록 DTO
struct AlarmSoundDTO: Codable {
    let soundId: String
    let displayName: String
    let isDefault: Bool
}

// MARK: - Extensions (Mapping Logic)
extension Alarm {
    
    /// DTO로부터 Alarm 모델 생성 (서버 데이터 -> 앱 모델)
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
    
    /// Alarm 모델을 생성/수정 요청용 Dictionary로 변환 (앱 모델 -> 서버 요청 Body)
    func toDictionary() -> [String: Any] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        return [
            "alarmTime": timeFormatter.string(from: self.time),
            "label": self.label,
            "isEnabled": self.isEnabled,
            "soundType": self.soundName,
            "vibration": true,
            "volume": 100,
            "repeatDays": Alarm.convertRepeatDaysToString(self.repeatDays),
            "snoozeSetting": [
                "isEnabled": true,
                "intervalSec": 300,
                "maxCount": 3
            ]
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
        return days.compactMap { dayMap[$0] }
    }
}
