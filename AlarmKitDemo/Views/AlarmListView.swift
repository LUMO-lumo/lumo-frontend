import SwiftUI
import Combine

// MARK: - 알람 목록 뷰
// 등록된 알람들을 리스트 형태로 보여주는 뷰입니다.
struct AlarmListView: View {
    @StateObject private var alarmManager = AlarmSoundManager.shared
    @State private var selectedAlarm: AlarmModel? // 편집을 위해 선택된 알람
    
    var body: some View {
        Group {
            // 알람이 하나도 없으면 빈 화면 표시
            if alarmManager.alarms.isEmpty {
                EmptyAlarmView()
            } else {
                // 알람 리스트
                List {
                    ForEach(alarmManager.alarms) { alarm in
                        AlarmRowView(alarm: alarm)
                            .contentShape(Rectangle()) // 행 전체를 터치 영역으로
                            .onTapGesture {
                                selectedAlarm = alarm // 탭하면 편집 시트 오픈
                            }
                    }
                    .onDelete(perform: deleteAlarms) // 스와이프 삭제
                }
            }
        }
        // 알람 편집 시트 (selectedAlarm이 nil이 아닐 때 표시됨)
        .sheet(item: $selectedAlarm) { alarm in
            AlarmDetailView(alarm: alarm, isNewAlarm: false)
        }
    }
    
    // 삭제 로직
    private func deleteAlarms(at offsets: IndexSet) {
        for index in offsets {
            let alarm = alarmManager.alarms[index]
            Task {
                // 매니저를 통해 시스템 알람과 로컬 데이터를 모두 삭제
                try? await alarmManager.cancelAlarm(alarm)
            }
        }
    }
}

// MARK: - 알람 행 (Row) 뷰
// 리스트의 각 아이템을 구성하는 뷰입니다.
struct AlarmRowView: View {
    let alarm: AlarmModel
    @StateObject private var alarmManager = AlarmSoundManager.shared
    
    var body: some View {
        HStack {
            // 왼쪽: 시간 및 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    // 비활성화되면 회색으로 표시
                    .foregroundColor(alarm.isEnabled ? .primary : .secondary)
                
                Text(alarm.label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(alarm.repeatDaysString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 오른쪽: On/Off 토글 스위치
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in
                    // 토글 값 변경 시 매니저 호출 (비동기)
                    Task {
                        try? await alarmManager.toggleAlarm(alarm)
                    }
                }
            ))
            .labelsHidden() // 토글 레이블 숨김
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 빈 알람 안내 뷰
struct EmptyAlarmView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("설정된 알람이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("오른쪽 상단의 + 버튼을 눌러\n새 알람을 추가하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    NavigationStack {
        AlarmListView()
    }
}
