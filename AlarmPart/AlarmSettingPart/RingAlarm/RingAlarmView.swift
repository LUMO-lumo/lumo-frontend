//
//  RingAlarmView.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.
//
//1. 알람이 울리고 잠금 풀기 유도,
//2. 알람 백그라운드에서 알람이 울리게 만들기
//3. 미션 화면으로 넘어가게 만드는 부분 연결
//4. 미션을 한 다음 브리핑하게 하는 부분 연결

//func scheduleAlarm(_ alarm: AlarmModel) async throws -> AlarmModel {
//        var updatedAlarm = alarm
//        
//        // 3. 현재 시간 기준으로 다음 알람 날짜(Date) 계산
//        let alarmDate = calculateNextAlarmDate(hour: alarm.hour, minute: alarm.minute)
//        
//        // --- [A] AlarmKit 등록 (시스템 알람) ---
//        let schedule = Alarm.Schedule.fixed(alarmDate) // 계산된 날짜로 스케줄 생성
//        
//        let alert = AlarmPresentation.Alert(
//            title: LocalizedStringResource(stringLiteral: alarm.label)
//        )
//        
//        let presentation = AlarmPresentation(alert: alert)
//        
//        let attributes = AlarmAttributes<EmptyAlarmMetadata>(
//            presentation: presentation,
//            tintColor: Color.orange
//        )
//        
//        let config = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.alarm(
//            schedule: schedule,
//            attributes: attributes
//        )
//        
//        let alarmId = UUID()
//        // 실제 AlarmKit에 등록되는 시점
//        try await alarmManager.schedule(id: alarmId, configuration: config)
//        updatedAlarm.alarmIdentifier = alarmId
//        
//        // --- [B] Local Notification 등록 (잠금 화면 사운드용) ---
//        await scheduleLocalNotification(for: updatedAlarm, at: alarmDate)
//        
//        // ... (로컬 저장 로직 생략)
//        
//        return updatedAlarm
//    }
//
//    // 날짜 계산 로직 (오늘 지났으면 내일로)
//    private func calculateNextAlarmDate(hour: Int, minute: Int) -> Date {
//        let calendar = Calendar.current
//        var components = DateComponents()
//        components.hour = hour
//        components.minute = minute
//        components.second = 0
//        
//        var alarmDate = calendar.nextDate(
//            after: Date(),
//            matching: components,
//            matchingPolicy: .nextTime
//        ) ?? Date()
//        
//        if alarmDate <= Date() {
//            alarmDate = calendar.date(byAdding: .day, value: 1, to: alarmDate) ?? alarmDate
//        }
//        
//        return alarmDate
//    }
//
//    // Local Notification 등록 로직
//    private func scheduleLocalNotification(for alarm: AlarmModel, at date: Date) async {
//        let content = UNMutableNotificationContent()
//        content.title = "⏰ 알람"
//        content.body = alarm.label
//        content.categoryIdentifier = "ALARM_CATEGORY"
//        
//        // 커스텀 사운드 설정 (잠금 화면에서 울릴 파일 지정)
//        let soundFileName = findSoundFile(named: alarm.soundName)
//        if let fileName = soundFileName {
//            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
//        } else {
//            content.sound = .defaultCritical
//        }
//        
//        // 중요: 방해 금지 모드 무시
//        content.interruptionLevel = .timeSensitive
//        
//        // 트리거 설정
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
//        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
//        
//        let request = UNNotificationRequest(
//            identifier: alarm.id.uuidString,
//            content: content,
//            trigger: trigger
//        )
//        
//        do {
//            try await UNUserNotificationCenter.current().add(request)
//            print("📱 Local Notification 스케줄됨: \(alarm.timeString)")
//        } catch {
//            print("Local Notification 스케줄링 실패: \(error)")
//        }
//    }
