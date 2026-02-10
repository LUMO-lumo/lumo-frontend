import Foundation
import AlarmKit
import AVFoundation
import SwiftUI
import Combine
import UserNotifications
import ActivityKit

// MARK: - 빈 Metadata 타입 정의
// AlarmAttributes에 제네릭으로 전달할 메타데이터입니다. 특별한 데이터가 없으므로 빈 구조체로 정의합니다.
struct EmptyAlarmMetadata: AlarmMetadata {}

// MARK: - 알람 및 사운드 관리 매니저 (ViewModel + Service)
// NSObject를 상속받는 이유는 UNUserNotificationCenterDelegate를 채택하기 위함입니다.
@MainActor
class AlarmSoundManager: NSObject, ObservableObject {
    // 싱글톤 패턴: 앱 전체에서 하나의 매니저 인스턴스만 사용합니다.
    static let shared = AlarmSoundManager()
    
    // MARK: - Published Properties (UI 업데이트 트리거)
    @Published var alarms: [AlarmModel] = []       // 알람 목록 데이터
    @Published var isAuthorized: Bool = false      // 권한 승인 여부
    @Published var isAlarmPlaying: Bool = false    // 현재 알람(사운드) 재생 중인지 여부
    
    // 오디오 재생기 (mp3, wav 파일 재생용)
    private var audioPlayer: AVAudioPlayer?
    
    // 데이터 저장을 위한 UserDefaults 키
    private let userDefaultsKey = "savedAlarms"
    
    // AlarmKit의 매니저 인스턴스
    private let alarmManager = AlarmManager.shared
    
    // 현재 울리고 있는 알람의 사운드 파일명 저장
    private var currentSoundName: String?
    
    // 사용 가능한 사운드 리소스 목록 (Bundle에 포함된 파일명과 일치해야 함)
    let availableSounds = [
        "alexgrohl-burn-the-track-inspiring-rock-trailer-478796",
        "kornevmusic-epic-478847",
        "alex-20sec"
    ]
    
    // MARK: - 초기화
    private override init() {
        super.init()
        setupAudioSessionForAlarm() // 오디오 세션 설정
        loadAlarms()                // 저장된 알람 불러오기
        setupNotifications()        // 로컬 알림 설정 (Delegate 연결)
        
        // 비동기로 권한 상태 확인
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - 알림(Notification) 설정
    // 앱이 실행될 때 로컬 알림 델리게이트를 설정합니다.
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        // 알림 권한(배너, 사운드, 뱃지) 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 승인됨")
            } else {
                print("❌ 알림 권한 거부됨")
            }
        }
    }
    
    // MARK: - 백그라운드 오디오 세션 설정
    // 앱이 백그라운드 상태이거나 화면이 꺼져 있어도 소리가 나도록 설정합니다.
    private func setupAudioSessionForAlarm() {
        do {
            // .playback: 무음 모드에서도 소리 재생
            // .duckOthers: 다른 앱의 소리를 줄이고 이 앱의 소리를 강조
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 커스텀 알람 사운드 재생 (Core Logic)
    // 알림이 트리거되었을 때 실제로 음악 파일을 재생하는 함수입니다.
    func playCustomAlarmSound(soundName: String) {
        // 재생 전 오디오 세션 활성화
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("오디오 세션 활성화 실패: \(error)")
        }
        
        // 지원하는 확장자 목록을 순회하며 파일 찾기
        let extensions = ["mp3", "wav", "m4a", "caf"]
        var url: URL?
        
        for ext in extensions {
            if let foundUrl = Bundle.main.url(forResource: soundName, withExtension: ext) {
                url = foundUrl
                break
            }
        }
        
        guard let soundUrl = url else {
            print("⚠️ 사운드 파일 없음: \(soundName)")
            return
        }
        
        do {
            // AVAudioPlayer 인스턴스 생성 및 재생
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer?.numberOfLoops = -1 // -1은 무한 반복을 의미
            audioPlayer?.volume = 1.0       // 최대 볼륨
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isAlarmPlaying = true // UI에 오버레이를 띄우기 위한 상태 변경
            currentSoundName = soundName
            
            print("🔔 커스텀 알람 사운드 재생 시작: \(soundName)")
        } catch {
            print("알람 사운드 재생 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 알람 사운드 중지
    // 사용자가 '중지' 버튼을 눌렀을 때 호출됩니다.
    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmPlaying = false
        currentSoundName = nil
        print("🔕 알람 사운드 중지")
    }
    
    // MARK: - 권한 상태 확인
    func checkAuthorizationStatus() async {
        do {
            let state = try await alarmManager.requestAuthorization()
            isAuthorized = (state == .authorized)
        } catch {
            print("권한 상태 확인 실패: \(error)")
            isAuthorized = false
        }
    }
    
    // MARK: - 권한 요청 (Public)
    // UI에 반영되게하는 확인용 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let state = try await alarmManager.requestAuthorization()
            isAuthorized = (state == .authorized)
            return isAuthorized
        } catch {
            print("권한 요청 실패: \(error)")
            return false
        }
    }
    
    // MARK: - 알람 스케줄링 (핵심: AlarmKit + Local Notification)
    // alarmkit 이용한 기본 알람 기능 구현
    // 두 가지 시스템을 동시에 예약합니다.
    // 1. AlarmKit: 시스템 알람 UI 및 확실한 깨우기 보장
    // 2. Local Notification: 앱을 깨워서 커스텀 사운드(mp3)를 재생하는 트리거
    func scheduleAlarm(_ alarm: AlarmModel) async throws -> AlarmModel {
        var updatedAlarm = alarm
        
        // 현재 시간 기준으로 다음 알람 날짜 계산
        let alarmDate = calculateNextAlarmDate(hour: alarm.hour, minute: alarm.minute)
        
        // --- 1. AlarmKit 알람 스케줄링 ---
        let schedule = Alarm.Schedule.fixed(alarmDate)
        
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarm.label),
        )
        
        let presentation = AlarmPresentation(alert: alert)
        
        // 화면이 켜져있을 때 알람이 울리는 부분
        let attributes = AlarmAttributes<EmptyAlarmMetadata>(
            presentation: presentation,
            tintColor: Color.orange
        )
        
        // 잠금상태일 때 알람이 울리는 기본 기능 구현
        let config = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            sound: .named("alex-20sec.mp3")
        )
        
        let alarmId = UUID()
        // AlarmKit에 등록
        try await alarmManager.schedule(id: alarmId, configuration: config)
        updatedAlarm.alarmIdentifier = alarmId // 나중에 취소하기 위해 ID 저장
        
        // --- 2. Local Notification 스케줄링 (커스텀 사운드 재생용) ---
        //MARK: UserNotification을 이용한 거
        // 잠금상테에서 울리게 하는 함수를 연결한 부분
        await scheduleLocalNotification(for: updatedAlarm, at: alarmDate)
        
        // 로컬 데이터(배열) 업데이트 및 저장
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = updatedAlarm
        } else {
            alarms.append(updatedAlarm)
        }
        saveAlarms()
        
        print("✅ 알람 스케줄됨: \(alarm.timeString) - 사운드: \(alarm.soundName)")
        return updatedAlarm
    }
    
    // MARK: - Local Notification 등록
    // 잠금화면에서 울리게 하는 함수
    private func scheduleLocalNotification(for alarm: AlarmModel, at date: Date) async {
        
        if let path = Bundle.main.path(forResource: "alex-20sec", ofType: "mp3") {
            print("✅ 파일 찾음! 경로: \(path)")
        } else {
            print("❌ 파일 못 찾음! (파일명이나 Target Membership 문제)")
        }
        
        //위젯으로 알람이 오게 하는 부분
        let content = UNMutableNotificationContent()
        content.title = "⏰ 알람"
        content.body = alarm.label
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // 30초 제한이 있는 알림 사운드 설정
        
        // Critical Alert: 무음 모드 무시 (권한 필요, 여기서는 timeSensitive로 설정)
        content.interruptionLevel = .timeSensitive
        
        let soundFileName = "\(alarm.soundName).mp3"
            
            // 시스템에게 "이 파일 틀어줘"라고 명령
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alex-20sec.mp3"))
        
        // 정확한 날짜/시간에 트리거 설정
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 요청 생성
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString, // AlarmModel의 ID 사용
            content: content,
            trigger: trigger
        )
        
        do {
            // 알림 센터에 추가
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Local Notification 스케줄됨: \(alarm.timeString)")
        } catch {
            print("Local Notification 스케줄링 실패: \(error)")
        }
    }
    
    // MARK: - 헬퍼: 사운드 파일명 찾기
    private func findSoundFile(named soundName: String) -> String? {
        let extensions = ["mp3", "wav", "m4a", "caf", "aiff"]
        
        for ext in extensions {
            let fileName = "\(soundName).\(ext)"
            if Bundle.main.url(forResource: soundName, withExtension: ext) != nil {
                return fileName
            }
        }
        return nil
    }
    
    // MARK: - 알람 취소
    func cancelAlarm(_ alarm: AlarmModel) async throws {
        // 1. AlarmKit에서 제거
        if let identifier = alarm.alarmIdentifier {
            try alarmManager.cancel(id: identifier)
            print("🗑️ 알람 취소됨: \(alarm.timeString)")
        }
        
        // 2. Local Notification 제거
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        
        // 3. 로컬 목록에서 제거
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    // MARK: - 알람 켜기/끄기 (토글)
    func toggleAlarm(_ alarm: AlarmModel) async throws {
        var updatedAlarm = alarm
        updatedAlarm.isEnabled.toggle()
        
        if updatedAlarm.isEnabled {
            // 켜는 경우: 다시 스케줄링
            _ = try await scheduleAlarm(updatedAlarm)
        } else {
            // 끄는 경우: 예약된 알람들 취소 (데이터는 유지)
            if let identifier = alarm.alarmIdentifier {
                try alarmManager.cancel(id: identifier)
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
            
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index] = updatedAlarm
            }
            saveAlarms()
        }
    }
    
    // MARK: - 날짜 계산 로직
    // 현재 시간보다 이전이면 내일로, 이후면 오늘로 설정
    // 기본 캘린더 기능 사용
    private func calculateNextAlarmDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        var alarmDate = calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()
        
        if alarmDate <= Date() {
            alarmDate = calendar.date(byAdding: .day, value: 1, to: alarmDate) ?? alarmDate
        }
        
        return alarmDate
    }
    
    // MARK: - 사운드 선택 화면용 미리듣기
    func previewSound(named soundName: String) {
        stopPreview() // 기존 재생 중인 것이 있다면 중지
        
        let extensions = ["mp3", "wav", "m4a", "caf"]
        var url: URL?
        
        for ext in extensions {
            if let foundUrl = Bundle.main.url(forResource: soundName, withExtension: ext) {
                url = foundUrl
                break
            }
        }
        
        guard let soundUrl = url else {
            print("⚠️ 사운드 파일 없음: \(soundName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer?.numberOfLoops = 0 // 미리듣기는 한 번만 재생
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("🔊 사운드 미리듣기: \(soundName)")
        } catch {
            print("사운드 재생 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 미리듣기 중지
    func stopPreview() {
        // 실제 알람이 울리고 있는 중이 아닐 때만 플레이어를 정지시킴
        if !isAlarmPlaying {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
    
    // MARK: - 데이터 영구 저장 (UserDefaults)로컬 저장소
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([AlarmModel].self, from: data) {
            alarms = decoded
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate 구현
extension AlarmSoundManager: UNUserNotificationCenterDelegate {
    
    // 1. 앱이 켜져있을 때 (포그라운드)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge])
        
        Task { @MainActor in
            // 알림 ID와 일치하는 알람을 찾아서 그 알람의 설정된 소리를 재생
            let reqId = notification.request.identifier
            if let alarm = AlarmSoundManager.shared.alarms.first(where: { $0.id.uuidString == reqId }) {
                AlarmSoundManager.shared.playCustomAlarmSound(soundName: alarm.soundName)
            } else {
                // 못 찾으면 기본값
                AlarmSoundManager.shared.playCustomAlarmSound(soundName: "alex-20sec")
            }
        }
    }
    
    // 2. 알림 배너를 눌렀을 때 (백그라운드 -> 앱 진입)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            print("📱 알림 탭 -> 앱 열림: 사운드 계속 재생")
            
            // 1. 알림 ID 확인
            let reqId = response.notification.request.identifier
            
            // 2. 저장된 알람 목록에서 ID가 같은 녀석을 찾음
            let matchingAlarm = AlarmSoundManager.shared.alarms.first(where: { $0.id.uuidString == reqId })
            
            // 3. 그 알람의 소리 이름 가져오기 (없으면 기본값)
            let soundName = matchingAlarm?.soundName ?? "alex-20sec"
            
            // 4. 재생
            AlarmSoundManager.shared.isAlarmPlaying = true
            AlarmSoundManager.shared.playCustomAlarmSound(soundName: soundName)
        }
        completionHandler()
    }
}
