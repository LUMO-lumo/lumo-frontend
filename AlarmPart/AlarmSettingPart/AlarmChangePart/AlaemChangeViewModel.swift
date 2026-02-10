//
//  AlaemChangeViewModel.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/3/26.
//

import SwiftUI
import Combine
import UserNotifications
import AlarmKit
import Foundation

class AlarmChangeViewModel: ObservableObject {
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = []
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = false
    
    // [연동] SoundSettingView와 바인딩되는 변수
    @Published var alarmSound: String = "기본음"
    
    private var originalAlarm: Alarm?
    
    init(alarm: Alarm? = nil) {
        self.originalAlarm = alarm
        
        if let alarm = alarm {
            print("[Debug] 알람 데이터 로드: \(alarm.label)")
            
            self.alarmTitle = alarm.label
            self.selectedTime = alarm.time
            self.isSoundOn = alarm.isEnabled
            self.selectedDays = Set(alarm.repeatDays.map { ($0 + 6) % 7 })
            
            // [추가됨] 저장된 사운드 불러오기
            self.alarmSound = alarm.soundName
            
            switch alarm.missionType {
            case "계산": self.selectedMission = "수학문제"
            case "받아쓰기": self.selectedMission = "따라쓰기"
            case "운동": self.selectedMission = "거리미션"
            case "OX": self.selectedMission = "OX 퀴즈"
            default: self.selectedMission = "수학문제"
            }
        }
    }
    
    func getUpdatedAlarm() -> Alarm {
        let mappedDays = selectedDays.map { ($0 + 1) % 7 }.sorted()

        let mType: String
        switch selectedMission {
        case "수학문제": mType = "계산"
        case "따라쓰기": mType = "받아쓰기"
        case "거리미션": mType = "운동"
        case "OX 퀴즈": mType = "OX"
        default: mType = "계산"
        }
        
        if var alarm = originalAlarm {
            alarm.label = alarmTitle
            alarm.time = selectedTime
            alarm.isEnabled = isSoundOn
            alarm.repeatDays = mappedDays
            alarm.missionType = mType
            alarm.missionTitle = selectedMission
            
            // [추가됨] 사운드 저장
            alarm.soundName = alarmSound
            
            return alarm
        } else {
             return Alarm(
                time: selectedTime,
                label: alarmTitle,
                isEnabled: isSoundOn,
                repeatDays: mappedDays,
                missionTitle: selectedMission,
                missionType: mType,
                soundName: alarmSound // [추가됨]
             )
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleAlarm() {}
}
