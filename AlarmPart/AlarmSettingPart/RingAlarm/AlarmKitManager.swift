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

// Framework의 Alarm 타입 별칭
typealias FrameworkAlarm = AlarmKit.Alarm

// AlarmKit에서 요구하는 메타데이터 구조체
struct EmptyAlarmMetadata: AlarmMetadata, Codable, Hashable {
    struct ContentState: Codable, Hashable {}
}

@MainActor
final class AlarmKitManager {
    
    static let shared = AlarmKitManager()
    
    private init() {}
    
    /// 알람 스케줄링 (시스템 알람 + 로컬 알림)
    @MainActor
    func scheduleAlarm(from alarm: Alarm) async throws {
        
        // 1. 기존 알람 무조건 제거 (ID 기반)
        await removeAlarm(id: alarm.id)
        
        // ✅ [수정 포인트] 알람이 OFF 상태이면 삭제만 하고 여기서 종료 (스케줄링 안 함)
        guard alarm.isEnabled else {
            print("⏸️ [AlarmKit] 알람이 OFF 상태입니다. 스케줄링을 취소합니다.")
            return
        }
        
        // 2. 시/분 추출
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)
        
        // 3. 날짜 계산 (반복 요일 고려)
        let nextAlarmDate = calculateNextDate(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        
        // --- [A] AlarmKit 등록 (시스템 UI용) ---
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
        
        // 실제 AlarmKit에 스케줄 등록
        _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: config)
        print("✅ [AlarmKit] 등록 완료. 시간: \(nextAlarmDate), 사운드: \(alarm.soundName)")
        
        // --- [B] Local Notification 등록 (잠금화면 사운드 재생용) ---
        await scheduleLocalNotification(for: alarm, hour: hour, minute: minute)
    }
    
    /// 알람 삭제 (AlarmKit + Local Notification)
    func removeAlarm(id: UUID) async {
        try? AlarmManager.shared.cancel(id: id)
        
        let center = UNUserNotificationCenter.current()
        var identifiersToRemove = [id.uuidString]
        // 반복 알람의 경우 id_0, id_1 등의 식별자를 가짐
        for i in 0...6 {
            identifiersToRemove.append("\(id.uuidString)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        print("🗑️ [Manager] 로컬 알람/알림 삭제 완료: \(id)")
    }
    
    /// 다음 알람 날짜 계산 로직
    private func calculateNextDate(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 반복 요일이 없는 경우 (1회성)
        if repeatDays.isEmpty {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now
            return date
        }
        
        // 반복 요일이 있는 경우: 가장 가까운 미래의 요일 찾기
        var nextDates: [Date] = []
        for modelDay in repeatDays {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            // 모델의 0(일)~6(토)를 Calendar의 1(일)~7(토)로 매핑
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
        // 방해금지 모드 무시하고 소리 재생
        content.interruptionLevel = .timeSensitive
        
        if let fileName = SoundManager.shared.getSoundFileName(named: alarm.soundName) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(fileName).mp3"))
        } else if alarm.soundName == "안 함" {
            content.sound = nil
        } else {
            content.sound = .defaultCritical
        }
        
        // 1회성 알람 스케줄링
        if alarm.repeatDays.isEmpty {
            let nextDate = calculateNextDate(hour: hour, minute: minute, repeatDays: [])
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            try? await center.add(request)
        }
        // 요일 반복 알람 스케줄링
        else {
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
}
