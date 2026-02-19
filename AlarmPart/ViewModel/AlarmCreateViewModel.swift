//
//  AlarmCreateViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/19/26.
//

import Combine
import Foundation
import UserNotifications

import AlarmKit

class AlarmCreateViewModel: ObservableObject {
    
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = []
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = true
    
    // [연동] 사운드 저장 변수
    @Published var alarmSound: String = "기본음"
    
    func createNewAlarm() -> Alarm {
        let mappedDays = selectedDays.map { ($0 + 1) % 7 }.sorted()
        let mType: String
        
        switch selectedMission {
        case "수학문제":
            mType = "계산"
        case "따라쓰기":
            mType = "받아쓰기"
        case "거리미션":
            mType = "운동"
        case "OX 퀴즈":
            mType = "OX"
        default:
            mType = "계산"
        }
        
        // [추가됨] soundName 저장
        return Alarm(
            time: selectedTime,
            label: alarmTitle.isEmpty ? "새 알람" : alarmTitle,
            isEnabled: isSoundOn,
            repeatDays: mappedDays,
            missionTitle: selectedMission,
            missionType: mType,
            soundName: alarmSound
        )
    }
    // API 호출은 AlarmMenuView -> AlarmViewModel.addAlarm()에서 처리합니다.
}
