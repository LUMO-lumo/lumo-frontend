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
    @Published var triggeredAlarmId: Int? = nil
    
    // 🔥 [핵심 추가] 알람 취소를 위한 UUID 저장
    @Published var triggeredAlarmUUID: String? = nil
    
    // 🔥 [추가] 방금 완료한 알람의 UUID (Ghost 감지용)
    @Published var lastCompletedAlarmUUID: String? = nil
    
    // 🔥 [핵심 추가] 미션 완료 상태 플래그
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
    
    // MARK: - 알람 스케줄링
    
    // AlarmKitManager.swift 내부의 scheduleAlarm 함수

    // AlarmKitManager.swift

    func scheduleAlarm(from alarm: Alarm) async throws {
        // 🔥 [핵심 수정] 알람을 새로 예약한다는 건, 더 이상 '완료된 알람'이 아님 -> 차단 해제
        if lastCompletedAlarmUUID == alarm.id.uuidString {
            lastCompletedAlarmUUID = nil
            isMissionCompletedState = false
            print("🔓 [Unlock] 알람 재설정 감지 -> Ghost 차단 해제: \(alarm.id.uuidString)")
        }
        
        await removeAlarm(id: alarm.id)

        guard alarm.isEnabled else { return }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)
        
        let nextAlarmDate = calculateNextDate(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        let soundFileName = SoundManager.shared.getSoundFileName(named: alarm.soundName!) ?? "scream14-6918"
        
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
        } catch {
            print("⚠️ [1단계] AlarmKit 실패 (무시 가능)")
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
            } catch {
                print("⚠️ [2단계] Live Activity 실패 (무시 가능)")
            }
        }
        
        // [Step 3] 반복 로컬 알림
        await scheduleRepeatedNotifications(for: alarm, at: nextAlarmDate, soundName: soundFileName)
    }
    
    private func scheduleRepeatedNotifications(for alarm: Alarm, at date: Date, soundName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(alarm.label.isEmpty ? "기상 시간" : alarm.label)"
        content.body = "터치하여 \(alarm.missionType) 미션을 수행하고 알람을 끄세요!"
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive
        
        let sid = alarm.serverId ?? -1
        
        var userInfo: [String: Any] = [
            "soundFileName": soundName,
            "soundExtension": "mp3",
            "missionType": alarm.missionType,
            "missionTitle": alarm.missionTitle,
            "alarmLabel": alarm.label,
            "alarmId": sid,
            "alarmUUID": alarm.id.uuidString
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
                identifier: "\(baseId)_rep_\(i)",
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
    
    func cancelLocalNotifications(for uuidString: String) {
        let center = UNUserNotificationCenter.current()
        var identifiersToRemove: [String] = []
        identifiersToRemove.append(uuidString)
        for i in 0..<15 {
            identifiersToRemove.append("\(uuidString)_rep_\(i)")
            identifiersToRemove.append("\(uuidString)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        center.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        print("🧹 [Cleanup] 반복 알림 삭제: \(uuidString)")
    }
    
    // MARK: - 사운드 제어
    func playAlarmSound(fileName: String, extension ext: String = "mp3") {
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
    
    func stopAlarmSound() {
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
        }
        print("🔕 알람 소리 중단")
    }
    
    func completeMission() {
        print("🎉 [Success] 미션 성공! 모든 알림 및 소리 종료")
        
        isMissionCompletedState = true
        
        if let uuid = triggeredAlarmUUID {
            lastCompletedAlarmUUID = uuid
            cancelLocalNotifications(for: uuid)
        }
        
        stopAlarmSound()
        
        // 2분간 차단 (재설정 시 해제됨)
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            self.isMissionCompletedState = false
            self.lastCompletedAlarmUUID = nil
            print("🔄 [Reset] 미션 완료 상태 초기화")
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
        struct CompletionWrapper: @unchecked Sendable {
            let handler: (UNNotificationPresentationOptions) -> Void
        }
        let safeHandler = CompletionWrapper(handler: completionHandler)
        
        let incomingUUID = notification.request.content.userInfo["alarmUUID"] as? String
        
        _Concurrency.Task { @MainActor in
            // 🔥 [수정] 무조건 차단이 아니라, UUID가 '방금 완료한 그놈'일 때만 차단
            if AlarmKitManager.shared.isMissionCompletedState,
               let incoming = incomingUUID,
               incoming == AlarmKitManager.shared.lastCompletedAlarmUUID {
                
                print("🛡 [Block] 완료된 알람(Ghost)의 배너 표시 차단")
                safeHandler.handler([]) // 차단
            } else {
                safeHandler.handler([.banner, .list, .sound]) // 허용
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
        let alarmUUID = userInfo["alarmUUID"] as? String
        
        _Concurrency.Task { @MainActor in
            
            // Case 1: 미션 완료 상태에서의 유입 체크
            if AlarmKitManager.shared.isMissionCompletedState {
                if let incomingUUID = alarmUUID, incomingUUID == AlarmKitManager.shared.lastCompletedAlarmUUID {
                    print("🛡 [Guard] 완료된 알람의 잔여(Ghost) 유입 차단: \(incomingUUID)")
                    AlarmKitManager.shared.cancelLocalNotifications(for: incomingUUID)
                    return
                }
                print("🔓 [Pass] 미션 완료 상태지만 새로운 알림(UUID 불일치)이므로 실행")
            }
            
            // Case 2: 알람 재생 중 (소리만 방어, 화면은 진행)
            if AlarmKitManager.shared.isAlarmPlaying {
                // 패스
            } else {
                if let f = soundFileName, let e = soundExtension {
                    AlarmKitManager.shared.playAlarmSound(fileName: f, extension: e)
                } else {
                    AlarmKitManager.shared.playAlarmSound(fileName: "scream14-6918", extension: "mp3")
                }
            }
            
            if let mission = missionType {
                print("🎯 알림 탭 감지! 미션: \(mission)")
                
                AlarmKitManager.shared.triggeredMissionType = mission
                AlarmKitManager.shared.triggeredAlarmId = alarmId
                AlarmKitManager.shared.triggeredAlarmUUID = alarmUUID
                
                if let l = label {
                    AlarmKitManager.shared.triggeredAlarmLabel = l
                }
                
                AlarmKitManager.shared.isAlarmPlaying = true
                AlarmKitManager.shared.showMissionView = true
            }
        }
    }
}
