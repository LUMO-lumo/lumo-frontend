//
//  AlarmModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftData

// UI 테스트를 위해 우선 구조체로 정의합니다.
// 추후 SwiftData 적용 시 @Model class Alarm: Identifiable { ... } 형태로 변경 가능합니다.
struct Alarm: Identifiable {
    let id: UUID = UUID()
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: [Int] // 0: 일요일, 1: 월요일 ... 6: 토요일
    var missionTitle: String
    var missionType: String // 예: "계산", "받아쓰기"
    
    // 시간 표시를 위한 포맷터
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    // [수정] 스크롤 확인을 위해 적절한 8개의 더미 데이터로 조정했습니다.
    static let dummyData: [Alarm] = [
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
            label: "새벽 기상",
            isEnabled: true,
            repeatDays: [1, 2, 3, 4, 5],
            missionTitle: "물 한잔 마시기",
            missionType: "건강"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            label: "아침 기상",
            isEnabled: true,
            repeatDays: [1, 3, 5], // 월, 수, 금
            missionTitle: "수학 5문제 풀기",
            missionType: "계산"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date(),
            label: "영어 단어 암기",
            isEnabled: false,
            repeatDays: [2, 4], // 화, 목
            missionTitle: "영어 단어 10개 쓰기",
            missionType: "받아쓰기"
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
            label: "운동 가기",
            isEnabled: true,
            repeatDays: [0, 6], // 일, 토
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
