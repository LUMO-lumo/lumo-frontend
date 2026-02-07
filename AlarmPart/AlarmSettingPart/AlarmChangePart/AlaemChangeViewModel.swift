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
    // MARK: - UI 상태 프로퍼티
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = [] // 0:월 ~ 6:일 (View 기준)
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = false
    @Published var alarmSound: String = "안 함"
    
    // 원본 알람 저장용
    private var originalAlarm: Alarm?
    
    // MARK: - 초기화
    init(alarm: Alarm? = nil) {
        self.originalAlarm = alarm
        
        if let alarm = alarm {
            print("[Debug] 알람 데이터 수신 성공: \(alarm.label), 시간: \(alarm.timeString)")
            
            // 기존 알람 데이터를 UI 상태에 반영
            self.alarmTitle = alarm.label
            self.selectedTime = alarm.time
            self.isSoundOn = alarm.isEnabled
            
            // Model의 요일(0:일~6:토)을 View의 요일(0:월~6:일)로 변환
            // Logic: (ModelDay + 6) % 7 => ViewDay
            self.selectedDays = Set(alarm.repeatDays.map { ($0 + 6) % 7 })
            
            // 미션 타입 매핑
            switch alarm.missionType {
            case "계산": self.selectedMission = "수학문제"
            case "받아쓰기": self.selectedMission = "따라쓰기"
            case "운동": self.selectedMission = "거리미션"
            case "OX": self.selectedMission = "OX 퀴즈"
            default: self.selectedMission = "수학문제"
            }
        } else {
            print("[Debug] 알람 데이터가 전달되지 않았습니다 (새 알람 생성 모드).")
        }
    }
    
    // MARK: - Logic Methods
    
    /// 변경된 UI 상태를 바탕으로 업데이트된 Alarm 객체 반환
    func getUpdatedAlarm() -> Alarm {
        // 1. 요일 매핑 (View: 0:월~6:일 -> Model: 0:일~6:토)
        let mappedDays = selectedDays.map { ($0 + 1) % 7 }.sorted()

        // 2. 미션 타입 매핑
        let mType: String
        switch selectedMission {
        case "수학문제": mType = "계산"
        case "따라쓰기": mType = "받아쓰기"
        case "거리미션": mType = "운동"
        case "OX 퀴즈": mType = "OX"
        default: mType = "계산"
        }
        
        // 3. 알람 객체 생성 또는 업데이트
        if var alarm = originalAlarm {
            alarm.label = alarmTitle
            alarm.time = selectedTime
            alarm.isEnabled = isSoundOn
            alarm.repeatDays = mappedDays
            alarm.missionType = mType
            alarm.missionTitle = selectedMission
            return alarm
        } else {
            // (혹시 모를 예외 처리) 새 알람 생성
             return Alarm(
                time: selectedTime,
                label: alarmTitle,
                isEnabled: isSoundOn,
                repeatDays: mappedDays,
                missionTitle: selectedMission,
                missionType: mType
             )
        }
    }
    
    /// 알림 권한 요청 ----------원하는 부분에 넣으면 됨
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
    }
    
    /// 로컬 알림 스케줄링
    ///  UserNotifiaction을 이용한 위젯 알람
    func scheduleAlarm() {
        //잠금위젯에서 나오는 알람
        let content = UNMutableNotificationContent()
        content.title = alarmTitle.isEmpty ? "알람" : alarmTitle
        content.body = "\(selectedMission) 미션을 수행할 시간입니다!"
        content.sound = .default
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }
        
        // 1회성 알람
        if selectedDays.isEmpty {
            var triggerDate = DateComponents()
            triggerDate.hour = hour
            triggerDate.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("알람 등록 실패: \(error)")
                } else {
                    print("1회성 알람 등록 성공: \(hour):\(minute)")
                }
            }
        } else {
            // 반복 알람 (요일별 등록)
            for dayIndex in selectedDays {
                var triggerDate = DateComponents()
                triggerDate.hour = hour
                triggerDate.minute = minute
                
                let weekday: Int
                switch dayIndex {
                case 6: weekday = 1 // 일요일
                default: weekday = dayIndex + 2 // 월~토
                }
                triggerDate.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
                let request = UNNotificationRequest(identifier: "\(UUID().uuidString)_\(dayIndex)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
            print("반복 알람 등록 완료")
        }
    }
}
