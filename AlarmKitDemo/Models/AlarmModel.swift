import Foundation

// MARK: - 알람 데이터 모델
// Identifiable: SwiftUI 리스트에서 고유하게 식별하기 위함
// Codable: UserDefaults에 JSON 형태로 저장하기 위함
struct AlarmModel: Identifiable, Codable {
    let id: UUID
    var hour: Int
    var minute: Int
    var label: String
    var soundName: String
    var snoozeMinutes: Int
    var isEnabled: Bool
    var repeatDays: [Int]  // 요일 인덱스 저장 (0 = 일요일, 1 = 월요일, ...)
    var alarmIdentifier: UUID? // AlarmKit에 등록된 스케줄 ID 저장용
    
    // 초기화 메서드 (기본값 제공)
    init(
        id: UUID = UUID(),
        hour: Int = 7,
        minute: Int = 0,
        label: String = "알람",
        soundName: String = "alarm_default",
        snoozeMinutes: Int = 5,
        isEnabled: Bool = true,
        repeatDays: [Int] = [],
        alarmIdentifier: UUID? = nil
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.soundName = soundName
        self.snoozeMinutes = snoozeMinutes
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.alarmIdentifier = alarmIdentifier
    }
    
    // 시간을 "07:00" 형태의 문자열로 변환
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    // 반복 요일을 문자열로 변환 (예: "월, 수, 금")
    var repeatDaysString: String {
        if repeatDays.isEmpty {
            return "반복 안 함"
        }
        let dayNames = ["일", "월", "화", "수", "목", "금", "토"]
        // 요일 인덱스를 정렬한 후 이름으로 변환하고 콤마로 연결
        return repeatDays.sorted().map { dayNames[$0] }.joined(separator: ", ")
    }
}
