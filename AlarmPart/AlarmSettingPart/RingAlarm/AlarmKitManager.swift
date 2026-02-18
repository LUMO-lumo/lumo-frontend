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
import AVFoundation
import Combine      // @Published 및 ObservableObject 사용을 위해 필수
import ActivityKit  // .named() 등 Live Activity 관련 기능 사용을 위해 필수

// Framework의 Alarm 타입 별칭
typealias FrameworkAlarm = AlarmKit.Alarm

// AlarmKit에서 요구하는 메타데이터 구조체
struct EmptyAlarmMetadata: AlarmMetadata, Codable, Hashable {
    struct ContentState: Codable, Hashable {}
}

// ✅ NSObject, ObservableObject 채택 (알람 울림 상태 관리를 위해)
@MainActor
final class AlarmKitManager: NSObject, ObservableObject {
    
    static let shared = AlarmKitManager()
    
    // ✅ 현재 알람이 울리고 있는지 여부 (UI에서 감지하여 오버레이 표시)
    @Published var isAlarmPlaying: Bool = false
    
    // ✅ 알람 소리 재생용 플레이어
    private var audioPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        setupNotifications() // 델리게이트 연결
        setupAudioSessionForAlarm() // 오디오 세션 설정
    }
    
    // MARK: - 초기 설정
    
    private func setupNotifications() {
        // 델리게이트를 self로 설정하여 알림 수신 이벤트를 직접 처리
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func setupAudioSessionForAlarm() {
        do {
            // 무음 모드에서도 소리가 나고, 다른 앱 소리를 줄이도록 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 오디오 세션 설정 실패: \(error)")
        }
    }
    
    // MARK: - 알람 스케줄링 (핵심 로직)
    
    // AlarmKitManager.swift 내부의 scheduleAlarm 함수

    // AlarmKitManager.swift

    func scheduleAlarm(from alarm: Alarm) async throws {
        
        // 1. 기존 알람 제거
        await removeAlarm(id: alarm.id)
        
        guard alarm.isEnabled else { return }
        
        // 2. 날짜 계산
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)
        let second = calendar.component(.second, from: alarm.time)
        
        let nextAlarmDate = calculateNextDate(hour: hour, minute: minute, second: second, repeatDays: alarm.repeatDays)
        
        // 3. 사운드 파일명 준비 (로컬 알림용)
        let soundNameToCheck = alarm.soundName ?? ""
        let mappedFileName = SoundManager.shared.getSoundFileName(named: soundNameToCheck) ?? "scream14-6918"
        
        print("📢 알람 등록 예정: \(mappedFileName) / 시간: \(nextAlarmDate)")

        // --- [A] AlarmKit 등록 (시스템 UI용) ---
        // 여기서 사운드 설정을 제거하여 에러를 원천 차단합니다.
        let schedule = FrameworkAlarm.Schedule.fixed(nextAlarmDate)
        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: alarm.label))
        let presentation = AlarmPresentation(alert: alert)
        
        let attributes = AlarmAttributes<EmptyAlarmMetadata>(
            presentation: presentation,
            tintColor: Color.orange
        )
        
        // 🚨 [수정] sound 파라미터를 아예 삭제했습니다. (기본음으로 설정됨)
        let config = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes
        )
        
        _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: config)
        
        // --- [B] 로컬 알림(UserNotifications) 등록 (실제 소리 재생용) ---
        // 여기서 우리가 원하는 파일("천둥 번개" 등)을 재생하도록 합니다.
        await scheduleLocalNotification(for: alarm, hour: hour, minute: minute, second: second, soundName: mappedFileName)
    }
    /// 알람 삭제
    func removeAlarm(id: UUID) async {
        try? AlarmManager.shared.cancel(id: id)
        
        let center = UNUserNotificationCenter.current()
        var identifiersToRemove = [id.uuidString]
        for i in 0...6 {
            identifiersToRemove.append("\(id.uuidString)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        // 알람이 울리는 중이었다면 중지
        if isAlarmPlaying {
            stopAlarmSound()
        }
    }
    
    // MARK: - Local Notification (UserNotifications)
    
    // ✅ [수정] second 파라미터 추가
    private func scheduleLocalNotification(for alarm: Alarm, hour: Int, minute: Int, second: Int, soundName: String) async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        content.title = "⏰ \(alarm.label.isEmpty ? "알람" : alarm.label)"
        content.body = "알람을 끄려면 여기를 눌러 앱을 실행하세요."
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive // 중요 알림
        
        // ✅ [중요] 사운드 파일 설정 (확장자 매칭)
        if let ext = getFileExtension(for: soundName) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(soundName).\(ext)"))
            // userInfo에 사운드 파일명 저장 (알림 받았을 때 재생하기 위함)
            content.userInfo = ["soundFileName": soundName, "soundExtension": ext]
        } else {
            content.sound = .defaultCritical
        }
        
        // 트리거 설정 (반복 여부에 따라)
        if alarm.repeatDays.isEmpty {
            // ✅ [수정] 초 단위 반영
            let nextDate = calculateNextDate(hour: hour, minute: minute, second: second, repeatDays: [])
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            try? await center.add(request)
        } else {
            for modelDay in alarm.repeatDays {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                components.second = second // ✅ [수정] 초 단위 반영
                components.weekday = modelDay + 1
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "\(alarm.id.uuidString)_\(modelDay)", content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }
    
    // MARK: - 사운드 재생 제어
    
    func playAlarmSound(fileName: String, extension ext: String = "mp3") {
        // 오디오 세션 활성화
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio Session Error: \(error)") }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ 알람 사운드 파일 없음: \(fileName).\(ext)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // ✅ 무한 반복
            audioPlayer?.volume = 1.0       // 최대 볼륨
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            withAnimation {
                isAlarmPlaying = true // ✅ UI 오버레이 표시 트리거
            }
            print("🔊 알람 소리 재생 시작: \(fileName)")
        } catch {
            print("❌ 재생 실패: \(error)")
        }
    }
    
    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        withAnimation {
            isAlarmPlaying = false // ✅ UI 오버레이 숨김
        }
        print("🔕 알람 소리 중지됨")
    }
    
    // MARK: - Helpers
    
    // ✅ [수정] second 파라미터 추가 및 로직 반영
    private func calculateNextDate(hour: Int, minute: Int, second: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        if repeatDays.isEmpty {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = second // ✅ 초 단위 설정
            
            // 만약 현재 시각보다 이전이라면 내일로 설정
            let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now
            return date
        }
        
        var nextDates: [Date] = []
        for modelDay in repeatDays {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = second // ✅ 초 단위 설정
            components.weekday = modelDay + 1
            if let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                nextDates.append(date)
            }
        }
        return nextDates.min() ?? now
    }
    
    private func getFileExtension(for name: String) -> String? {
        if Bundle.main.url(forResource: name, withExtension: "mp3") != nil { return "mp3" }
        if Bundle.main.url(forResource: name, withExtension: "wav") != nil { return "wav" }
        if Bundle.main.url(forResource: name, withExtension: "m4a") != nil { return "m4a" }
        return nil
    }
}

// MARK: - UNUserNotificationCenterDelegate (알림 수신 처리)
extension AlarmKitManager: UNUserNotificationCenterDelegate {
    
    // 1. 앱이 켜져 있을 때 (Foreground)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 배너 표시
        completionHandler([.banner, .list, .badge, .sound])
        
        // 🚨 [유지] Data Race 방지: Task 밖에서 필요한 값 추출
        let userInfo = notification.request.content.userInfo
        let fileName = userInfo["soundFileName"] as? String
        let ext = userInfo["soundExtension"] as? String
        
        if let fileName = fileName, let ext = ext {
            _Concurrency.Task { @MainActor in
                AlarmKitManager.shared.playAlarmSound(fileName: fileName, extension: ext)
            }
        }
    }
    
    // 2. 알림을 탭해서 앱으로 들어왔을 때 (Background -> Foreground)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 🚨 [유지] Data Race 방지
        let userInfo = response.notification.request.content.userInfo
        let fileName = userInfo["soundFileName"] as? String
        let ext = userInfo["soundExtension"] as? String
        
        if let fileName = fileName, let ext = ext {
            _Concurrency.Task { @MainActor in
                AlarmKitManager.shared.playAlarmSound(fileName: fileName, extension: ext)
            }
        }
        
        completionHandler()
    }
}
