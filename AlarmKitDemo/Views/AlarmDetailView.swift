import SwiftUI

// MARK: - 알람 상세 편집/추가 뷰
// 새 알람을 만들거나 기존 알람을 수정하는 폼(Form)입니다.
struct AlarmDetailView: View {
    @Environment(\.dismiss) private var dismiss // 화면 닫기 액션
    @StateObject private var alarmManager = AlarmSoundManager.shared
    
    @State var alarm: AlarmModel // 편집 중인 알람 객체 (복사본)
    let isNewAlarm: Bool         // 새 알람 추가 모드인지 여부
    
    @State private var selectedTime = Date() // DatePicker 바인딩용 시간
    @State private var isSaving = false      // 저장 중 로딩 상태 표시
    
    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. 시간 선택 섹션
                Section {
                    DatePicker(
                        "알람 시간",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel) // 휠 스타일 피커
                    .labelsHidden()
                }
                
                // 2. 알람 세부 정보 섹션
                Section("알람 정보") {
                    TextField("레이블", text: $alarm.label)
                    
                    // 사운드 선택 화면으로 이동
                    NavigationLink {
                        SoundPickerView(selectedSound: $alarm.soundName)
                    } label: {
                        HStack {
                            Text("사운드")
                            Spacer()
                            Text(alarm.soundName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 스누즈(다시 알림) 시간 설정
                    Stepper("스누즈: \(alarm.snoozeMinutes)분", value: $alarm.snoozeMinutes, in: 1...15)
                }
                
                // 3. 반복 요일 설정 섹션
                Section("반복") {
                    ForEach(0..<7, id: \.self) { day in
                        Toggle(weekdays[day], isOn: Binding(
                            // 해당 요일이 포함되어 있는지 확인
                            get: { alarm.repeatDays.contains(day) },
                            // 토글 변경 시 배열에 추가하거나 제거
                            set: { isOn in
                                if isOn {
                                    if !alarm.repeatDays.contains(day) {
                                        alarm.repeatDays.append(day)
                                    }
                                } else {
                                    alarm.repeatDays.removeAll { $0 == day }
                                }
                            }
                        ))
                    }
                }
                
                // 4. 저장 버튼
                Section {
                    Button {
                        saveAlarm()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text(isNewAlarm ? "알람 추가" : "저장")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving) // 저장 중 중복 클릭 방지
                }
                
                // 5. 삭제 버튼 (기존 알람 편집 시에만 표시)
                if !isNewAlarm {
                    Section {
                        Button(role: .destructive) {
                            deleteAlarm()
                        } label: {
                            HStack {
                                Spacer()
                                Text("알람 삭제")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNewAlarm ? "새 알람" : "알람 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            // 뷰가 나타날 때 기존 알람 시간으로 DatePicker 초기화
            .onAppear {
                setupInitialTime()
            }
        }
    }
    
    // 알람 객체의 시간(Int)을 Date 객체로 변환하여 DatePicker에 반영
    private func setupInitialTime() {
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        if let date = Calendar.current.date(from: components) {
            selectedTime = date
        }
    }
    
    // 알람 저장 로직
    private func saveAlarm() {
        isSaving = true
        
        // 선택된 DatePicker의 시간을 알람 객체에 반영
        let calendar = Calendar.current
        alarm.hour = calendar.component(.hour, from: selectedTime)
        alarm.minute = calendar.component(.minute, from: selectedTime)
        
        Task {
            do {
                // 매니저를 통해 스케줄링 (AlarmKit + Local Noti)
                _ = try await alarmManager.scheduleAlarm(alarm)
                await MainActor.run {
                    isSaving = false
                    dismiss() // 화면 닫기
                }
            } catch {
                print("알람 저장 실패: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
    
    // 알람 삭제 로직
    private func deleteAlarm() {
        Task {
            try? await alarmManager.cancelAlarm(alarm)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    AlarmDetailView(alarm: AlarmModel(), isNewAlarm: true)
}
