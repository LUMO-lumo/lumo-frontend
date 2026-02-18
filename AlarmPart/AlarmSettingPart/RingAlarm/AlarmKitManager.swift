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
import Combine
import ActivityKit

// ✅ [필수] AlarmKit과 Live Activity를 연동하기 위한 속성 정의
struct AlarmWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
    }
    var alarmLabel: String
}

// ✅ AlarmKit용 빈 메타데이터
struct EmptyAlarmMetadata: AlarmMetadata, Codable, Hashable {
    struct ContentState: Codable, Hashable {}
}

@MainActor
final class AlarmKitManager: NSObject, ObservableObject {
    
    static let shared = AlarmKitManager()
    
    // ✅ UI 상태 관리용 변수들
    @Published var isAlarmPlaying: Bool = false
    @Published var triggeredMissionType: String? = nil
    
    // 🔥 [추가] UI에 표시할 알람 제목 및 ID
    @Published var triggeredAlarmLabel: String = "알람"
    @Published var triggeredAlarmId: Int? = nil // ✅ 미션 API 호출을 위해 필요
    
    // 🔥 [핵심 추가] 알람 취소를 위한 UUID 저장 (미션 완료 시 예약 취소용)
    @Published var triggeredAlarmUUID: String? = nil
    
    // 🔥 [핵심 추가] 미션 완료 상태 플래그 (중복 알림 방지)
    @Published var isMissionCompletedState: Bool = false
    
    // 🔥 화면 전환 트리거
    @Published var showMissionView: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var currentActivity: Activity<AlarmWidgetAttributes>?
    
    private override init() {
        super.init()
        setupNotifications()
        setupAudioSessionForAlarm()
        
        _Concurrency.Task {
            try? await AlarmManager.shared.requestAuthorization()
        }
    }
    
    // MARK: - 초기 설정
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let openAppAction = UNNotificationAction(
            identifier: "ACTION_OPEN_APP",
            title: "🔔 앱 열고 미션 수행하기",
            options: [.foreground]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func setupAudioSessionForAlarm() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 오디오 세션 설정 실패: \(error)")
        }
    }
    
    // MARK: - 알람 스케줄링 (3중 안전장치)
    
    func scheduleAlarm(from alarm: Alarm) async throws {
        await removeAlarm(id: alarm.id)
        guard alarm.isEnabled else { return }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)
        
        let nextAlarmDate = calculateNextDate(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        let soundFileName = SoundManager.shared.getSoundFileName(named: alarm.soundName) ?? "scream14-6918"
        
        print("🔔 [Schedule] 알람 예약: \(nextAlarmDate) (미션: \(alarm.missionType))")
        
        // [Step 1] AlarmKit
        do {
            let schedule = AlarmKit.Alarm.Schedule.fixed(nextAlarmDate)
            let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: alarm.label))
            let presentation = AlarmPresentation(alert: alert)
            let attributes = AlarmAttributes<EmptyAlarmMetadata>(presentation: presentation, tintColor: .orange)
            
            let config = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.alarm(
                schedule: schedule,
                attributes: attributes,
                sound: .named("\(soundFileName).mp3")
            )
            try await AlarmManager.shared.schedule(id: alarm.id, configuration: config)
            print("✅ [1단계] AlarmKit 등록 성공")
        } catch {
            print("⚠️ [1단계] AlarmKit 등록 실패: \(error.localizedDescription)")
        }
        
        // [Step 2] Live Activity
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = AlarmWidgetAttributes(alarmLabel: alarm.label)
            let contentState = AlarmWidgetAttributes.ContentState(endTime: nextAlarmDate)
            let content = ActivityContent(state: contentState, staleDate: nil)
            
            do {
                currentActivity = try Activity<AlarmWidgetAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                print("✅ [2단계] Live Activity 시작됨")
            } catch {
                print("⚠️ [2단계] Live Activity 실패: \(error)")
            }
        }
        
        // [Step 3] 반복 로컬 알림
        await scheduleRepeatedNotifications(for: alarm, at: nextAlarmDate, soundName: soundFileName)
    }
    
    // 반복 알림 예약
    private func scheduleRepeatedNotifications(for alarm: Alarm, at date: Date, soundName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(alarm.label.isEmpty ? "기상 시간" : alarm.label)"
        content.body = "터치하여 \(alarm.missionType) 미션을 수행하고 알람을 끄세요!"
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive
        
        let sid = alarm.serverId ?? -1
        
        // ✅ [수정] 취소를 위해 UUID String을 userInfo에 저장
        var userInfo: [String: Any] = [
            "soundFileName": soundName,
            "soundExtension": "mp3",
            "missionType": alarm.missionType,
            "missionTitle": alarm.missionTitle,
            "alarmLabel": alarm.label,
            "alarmId": sid,
            "alarmUUID": alarm.id.uuidString // 🔥 핵심: 취소용 UUID
        ]
        
        if let ext = getFileExtension(for: soundName) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(soundName).\(ext)"))
            userInfo["soundExtension"] = ext
        } else {
            content.sound = .defaultCritical
        }
        content.userInfo = userInfo
        
        let baseId = alarm.id.uuidString
        
        for i in 0..<10 {
            let delay = TimeInterval(i * 5)
            let delayedDate = date.addingTimeInterval(delay)
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: delayedDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(baseId)_rep_\(i)", // 🔥 이 ID들을 나중에 지워야 함
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        print("✅ [3단계] 반복 알림(미션 포함) 예약 완료")
    }
    
    func removeAlarm(id: UUID) async {
        try? AlarmManager.shared.cancel(id: id)
        
        if let activity = currentActivity {
            _Concurrency.Task { await activity.end(nil, dismissalPolicy: .immediate) }
            currentActivity = nil
        }
        
        cancelLocalNotifications(for: id.uuidString)
        
        if isAlarmPlaying {
            stopAlarmSound()
        }
    }
    
    // 🔥 [추가] 로컬 알림 취소 헬퍼
    private func cancelLocalNotifications(for uuidString: String) {
        let center = UNUserNotificationCenter.current()
        var identifiersToRemove: [String] = []
        identifiersToRemove.append(uuidString)
        for i in 0..<15 {
            identifiersToRemove.append("\(uuidString)_rep_\(i)")
            identifiersToRemove.append("\(uuidString)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        center.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        print("🧹 [Cleanup] 예약된 반복 알림 삭제 완료: \(uuidString)")
    }
    
    // MARK: - 사운드 제어
    func playAlarmSound(fileName: String, extension ext: String = "mp3") {
        // 이미 울리고 있거나, 방금 미션을 깼다면 재생하지 않음
        guard !isAlarmPlaying && !isMissionCompletedState else { return }
        
        do { try AVAudioSession.sharedInstance().setActive(true) } catch {}
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            withAnimation { isAlarmPlaying = true }
            print("🔊 알람 소리 재생 시작")
        } catch { print("❌ 재생 실패: \(error)") }
    }
    
    // 단순히 소리만 끄는 함수 (슬라이드 중단 등)
    func stopAlarmSound() {
        // 소리만 끄더라도 예약된 알림은 취소해야 안전함
        if let uuid = triggeredAlarmUUID {
            cancelLocalNotifications(for: uuid)
        }
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        if let activity = currentActivity {
            _Concurrency.Task { await activity.end(nil, dismissalPolicy: .immediate) }
            currentActivity = nil
        }
        
        withAnimation {
            isAlarmPlaying = false
            showMissionView = false
            triggeredMissionType = nil
            triggeredAlarmId = nil
            triggeredAlarmUUID = nil
            // 여기서 isMissionCompletedState는 초기화하지 않음 (다음 알람을 위해 별도 타이밍에 하거나, 새 알람 시작 시 초기화)
        }
        print("🔕 알람 소리 중단")
    }
    
    // 🔥 [핵심 기능] 미션 완료 시 호출: 소리 끄고 + 남은 알림 폭파 + 상태 설정
    func completeMission() {
        print("🎉 [Success] 미션 성공! 모든 알림 및 소리 종료")
        
        // 1. 중복 실행 방지 플래그 설정
        isMissionCompletedState = true
        
        // 2. 예약된 잔여 알림(5초 뒤 올 것들) 즉시 삭제
        if let uuid = triggeredAlarmUUID {
            cancelLocalNotifications(for: uuid)
        }
        
        // 3. 소리 끄기 및 UI 정리
        stopAlarmSound()
        
        // 4. 상태 복구 예약 (다음 알람을 위해 1분 뒤 초기화)
        // 바로 false로 만들면 취소 직전에 큐에 있던 알림이 뚫고 들어올 수 있음
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.isMissionCompletedState = false
            print("🔄 [Reset] 미션 완료 상태 초기화 (다음 알람 대기)")
        }
    }
    
    // MARK: - Helpers
    private func calculateNextDate(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        if repeatDays.isEmpty {
            return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
        }
        
        var nextDates: [Date] = []
        for modelDay in repeatDays {
            components.weekday = modelDay + 1
            if let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                nextDates.append(date)
            }
        }
        return nextDates.min() ?? now.addingTimeInterval(60)
    }
    
    private func getFileExtension(for name: String) -> String? {
        if Bundle.main.url(forResource: name, withExtension: "mp3") != nil { return "mp3" }
        if Bundle.main.url(forResource: name, withExtension: "wav") != nil { return "wav" }
        if Bundle.main.url(forResource: name, withExtension: "m4a") != nil { return "m4a" }
        return nil
    }
}

// MARK: - Notification Delegate
extension AlarmKitManager: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // ✅ [수정] 컴파일러 에러 해결: nonisolated 함수 내부에 로컬 구조체를 정의하여 안전하게 감쌈
        struct CompletionWrapper: @unchecked Sendable {
            let handler: (UNNotificationPresentationOptions) -> Void
        }
        let safeHandler = CompletionWrapper(handler: completionHandler)
        
        _Concurrency.Task { @MainActor in
            // MainActor 상태(isMissionCompletedState) 확인
            if AlarmKitManager.shared.isMissionCompletedState {
                safeHandler.handler([]) // 알림 표시 안 함
            } else {
                safeHandler.handler([.banner, .list, .sound]) // 알림 표시
            }
        }
        handleNotification(notification)
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(response.notification)
        completionHandler()
    }
    
    private nonisolated func handleNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        let soundFileName = userInfo["soundFileName"] as? String
        let soundExtension = userInfo["soundExtension"] as? String
        let missionType = userInfo["missionType"] as? String
        let label = userInfo["alarmLabel"] as? String
        let alarmId = userInfo["alarmId"] as? Int
        let alarmUUID = userInfo["alarmUUID"] as? String // ✅ UUID 추출
        
        _Concurrency.Task { @MainActor in
            // 🔥 [방어 로직] 이미 미션을 깼거나, 알람이 울리고 있다면 무시
            if AlarmKitManager.shared.isMissionCompletedState || AlarmKitManager.shared.isAlarmPlaying {
                print("🛡 [Guard] 이미 미션 완료 또는 알람 재생 중 -> 중복 실행 방지")
                return
            }
            
            if let f = soundFileName, let e = soundExtension {
                AlarmKitManager.shared.playAlarmSound(fileName: f, extension: e)
            } else {
                AlarmKitManager.shared.playAlarmSound(fileName: "scream14-6918", extension: "mp3")
            }
            
            if let mission = missionType {
                print("🎯 알림 탭 감지! 미션: \(mission), UUID: \(alarmUUID ?? "nil")")
                
                AlarmKitManager.shared.triggeredMissionType = mission
                AlarmKitManager.shared.triggeredAlarmId = alarmId
                AlarmKitManager.shared.triggeredAlarmUUID = alarmUUID // ✅ 저장
                
                if let l = label {
                    AlarmKitManager.shared.triggeredAlarmLabel = l
                }
                
                AlarmKitManager.shared.isAlarmPlaying = true
                AlarmKitManager.shared.showMissionView = true
            }
        }
    }
}
