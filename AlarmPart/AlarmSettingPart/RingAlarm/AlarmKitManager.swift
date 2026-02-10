//
//  AlarmKitManager.swift
//  LUMO_PersonalDev
//
//  Created by AlarmKit Integration on 2/10/26.
//

import Foundation
import UserNotifications
import SwiftUI
import AlarmKit

typealias FrameworkAlarm = AlarmKit.Alarm

struct EmptyAlarmMetadata: AlarmMetadata, Codable, Hashable {
    struct ContentState: Codable, Hashable {}
}

@MainActor
final class AlarmKitManager {
    
    static let shared = AlarmKitManager()
    
    private init() {}
    
    @MainActor
    func scheduleAlarm(from alarm: Alarm) async throws {
        
        await removeAlarm(id: alarm.id)
        
        // 1. 시/분 추출
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)
        
        // 2. 날짜 계산
        let nextAlarmDate = calculateNextDate(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        
        // --- [A] AlarmKit 등록 ---
        let schedule = FrameworkAlarm.Schedule.fixed(nextAlarmDate)
        
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarm.label)
        )
        
        let presentation = AlarmPresentation(alert: alert)
        
        let attributes = AlarmAttributes<EmptyAlarmMetadata>(
            presentation: presentation,
            tintColor: Color.orange
        )
        
        let config = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes
        )
        
        _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: config)
        print("✅ [AlarmKit] 등록 완료. 시간: \(nextAlarmDate), 사운드: \(alarm.soundName)")
        
        // --- [B] Local Notification 등록 (사운드 포함) ---
        await scheduleLocalNotification(for: alarm, hour: hour, minute: minute)
    }
    
    func removeAlarm(id: UUID) async {
        try? AlarmManager.shared.cancel(id: id)
        
        let center = UNUserNotificationCenter.current()
        var identifiersToRemove = [id.uuidString]
        for i in 0...6 {
            identifiersToRemove.append("\(id.uuidString)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        print("🗑️ [Manager] 알람 삭제 완료: \(id)")
    }
    
    private func calculateNextDate(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        if repeatDays.isEmpty {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now
            return date
        }
        
        var nextDates: [Date] = []
        for modelDay in repeatDays {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            components.weekday = modelDay + 1
            if let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                nextDates.append(date)
            }
        }
        return nextDates.min() ?? now
    }
    
    // MARK: - Local Notification (사운드 설정 포함)
    private func scheduleLocalNotification(for alarm: Alarm, hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        content.title = "⏰ 알람"
        content.body = alarm.label.isEmpty ? "설정된 알람입니다" : alarm.label
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive
        
        // [추가됨] 사운드 설정 로직
        // 나중에 SoundManager를 만들 때 이 부분(getSoundFileName)을 잘라내서 가져가면 됩니다.
        let soundFileName = getSoundFileName(from: alarm.soundName)
        
        if let fileName = soundFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(fileName))
        } else if alarm.soundName == "안 함" {
            content.sound = nil
        } else {
            content.sound = .defaultCritical
        }
        
        if alarm.repeatDays.isEmpty {
            let nextDate = calculateNextDate(hour: hour, minute: minute, repeatDays: [])
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            try? await center.add(request)
        } else {
            for modelDay in alarm.repeatDays {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                components.weekday = modelDay + 1
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "\(alarm.id.uuidString)_\(modelDay)", content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }
    
    // [헬퍼] 사운드 이름 -> 파일명 매핑 (분리 용이하게 별도 함수로 작성)
    private func getSoundFileName(from displayName: String) -> String? {
        switch displayName {
        case "안 함", "기본음": return nil
            
        // 예시 매핑 (실제 파일명에 맞게 수정 필요)
        case "커피한잔의 여유": return "coffee.m4a"
        case "사이렌": return "siren.m4a"
        case "빗소리": return "rain.m4a"
            
        default: return nil
        }
    }
}
